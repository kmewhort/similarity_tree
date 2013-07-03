require 'matrix'
require 'tf-idf-similarity'
require 'fast_html_diff'

module SimilarityTree
  # Table of the diff/similarity scores between different text documents
  class SimilarityMatrix

    # Initialize a matrix for a set of documents
    def initialize(sources, options = {})
      @sources = sources
      @config = default_options.merge(options)

      @id = -1
      @source_index = Hash.new
      @matrix = nil
    end

    # calculate and output results as an array of arrays;
    # optional block is run each comparison to help with any progress bars
    def calculate
      if @config[:calculation_method] == :tf_idf
        @matrix = calculate_with_tf_idf
      elsif @config[:calculation_method] == :diff
        @matrix = calculate_with_diff
      else
        raise "Unknown calculation type"
      end
    end

    def build_tree(root_id, score_threshold = 0)
      # build the similarity tree
      @matrix = self.calculate if @matrix.nil?
      tree = SimilarityTree.new(root_id, @matrix, score_threshold).build

      # populate the nodes with the sources for the compatibility matrix
      tree.each_node {|n| n.content = @source_index[n.id] }
      tree
    end

    private
    def default_options
      {
          id_func: nil,
          content_func: nil,
          calculation_method: :tf_idf,
          show_progress: false
      }
    end

    def calculate_with_tf_idf
      progress_bar = nil
      if @config[:show_progress]
        progress_bar = ProgressBar.create format: '%a |%B| %p%% %e', length: 80, smoothing: 0.5,
                                         total: @sources.length
      end

      # iterate through the input texts and build the tf_idf corpus
      corpus = []
      ids = @sources.map do |source|
        corpus << TfIdfSimilarity::Document.new(text_of(source))
        progress_bar.increment unless progress_bar.nil?
        id_of(source)
      end
      model = TfIdfSimilarity::TfIdfModel.new(corpus, function: :tf_idf)
      similarity_matrix = model.similarity_matrix

      # compile the results into an ordinary m*n array
      matrix = {}
      ids.each_with_index do |a,i|
        matrix[a] = {}
        ids.each_with_index do |b,j|
          matrix[a][b] = similarity_matrix[i, j].round(6)
        end
      end
      matrix
    end

    # Create a similarity matrix, using diff as the similarity measure, based on the difference of WORDS (not characters)
    # (only counts insertions and deletions, not substitution and transposition).
    def calculate_with_diff
      progress_bar = nil
      if @config[:show_progress]
        progress_bar = ProgressBar.create format: '%a |%B| %p%% %e', length: 80, smoothing: 0.5,
                                         total: @sources.length*(@sources.length-1)/2
      end

      matrix = {}
      @sources.each_with_index do |a,i|
        a_id = id_of(a)
        a_text = text_of(a)

        @sources[i + 1..-1].each do |b|
          b_id   = id_of(b)
          b_text = text_of(b)

          stats = FastHtmlDiff::DiffBuilder.new(a_text, b_text).statistics

          # http://en.wikipedia.org/wiki/Dice%27s_coefficient
          total_count = 2 * stats[:matches][:words] + stats[:insertions][:words] + stats[:deletions][:words]
          similarity = 2 * stats[:matches][:words] / total_count.to_f

          # Build the similarity matrix,
          matrix[a_id] ||= {a_id => 1}
          matrix[a_id][b_id] = similarity
          matrix[b_id] ||= {b_id => 1}
          matrix[b_id][a_id] = similarity

          progress_bar.increment unless progress_bar.nil?
        end
      end
      matrix
    end

    def id_of(source)
      id = nil
      if !@config[:id_func].nil?
        id = source.send @config[:id_func].to_s
      else
        if is_a_filename? source
          id = File.basename(source)
        else
          id = @sources.find_index(source)
        end
      end

      # maintain an index of id => source
      @source_index[id] = source if @source_index[id].nil?
      id
    end

    def text_of(source)
      if !@config[:content_func].nil?
        txt = source.send @config[:content_func].to_s
      else
        txt = source
      end
      txt = File.read(txt) if is_a_filename?(txt)
      txt
    end

    # quick and dirty check on whether a string is a filename based on the string length and whether the file exists
    def is_a_filename?(filename)
      (filename.length < 512) && File.exists?(filename)
    end
  end
end