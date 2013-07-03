require 'json'
module SimilarityTree
  class Node
    attr_accessor :id, :diff_score, :parent, :children, :content

    def initialize(id, diff_score, parent = nil, children = [], content = nil)
      @id, @diff_score, @parent, @children, @content = id, diff_score, parent, children, content
    end

    # self and all descendents
    def each_node
      depth_first_recurse{|n, depth| yield n}
    end

    def to_s
      str = ""
      depth_first_recurse do |n, depth|
        str += ("-" * depth) + n.id.to_s
        str += ' (' + n.diff_score.to_s + ')' unless n.diff_score.nil?
        str += "\n"
      end
      str
    end

    def to_h
      result = {
          id: id
      }
      result[:children] = children.map {|c| c.to_h} unless children.nil? || children.empty?
      result[:diff_score] = diff_score unless diff_score.nil?

      # if the content node has an as_json function, merge-in these attributes
      if content.respond_to?(:as_json) && content.is_a?(Hash)
        result = content.as_json.merge(result)
      end
      result
    end

    def to_json(opts = {})
      JSON.generate to_h, opts
    end

    private
    # helper for recursion into descendents
    def depth_first_recurse(node = nil, depth = 0, &block)
      node = self if node == nil
      yield node, depth
      node.children.each do |child|
        depth_first_recurse(child, depth+1, &block)
      end
    end
  end
end