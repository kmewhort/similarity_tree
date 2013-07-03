module SimilarityTree

  # Constructs a hierarchy of nodes based on a specified root and the similarity "scores" between nodes. Each nodes is placed next
  # to the node to which it is most similar; as between two nodes, the node most similar to the root is placed closest to the root.
  class SimilarityTree
    # initialize/build the tree hierarchy from an existing similarity matrix
    def initialize(root_id, similarity_matrix, score_threshold = 0)
      @nodes = similarity_matrix.map {|key, row| Node.new(key, 0)}
      @root = @nodes.find {|n| n.id == root_id}
      @root.diff_score = nil
      @similarity_matrix = similarity_matrix
      @score_threshold = score_threshold
    end

    # build the tree and return the root node
    def build
      build_tree
      @root
    end

    private
    def build_tree
      tree = @root
      flat = [@root]

      # for each non-root node
      @nodes.delete_if{|n| n == @root}.map do |n|
        # find the best match to the nodes already in the tree
        closest_diff_score = 0
        closest = nil
        flat.each do |m|
          diff_score = @similarity_matrix[n.id][m.id]
          if closest.nil? || (diff_score > closest_diff_score)
            closest_diff_score = diff_score
            closest = m
          end
        end

        # if the closest match is the root node, or if the closest match's diff score with it's parent is stronger
        # than between the present node and that parent, add as a child of the match
        if (closest == @root) || (closest.diff_score >= @similarity_matrix[n.id][closest.parent.id])
          n.parent = closest
          closest.children << n
          n.diff_score = @similarity_matrix[n.id][closest.id]
          # else, if the new node is more similar to the parent, rotate so that the existing node becomes the child
        else
          # place children with the closest matching of the two
          closest.children.dup.each do |child|
            if @similarity_matrix[child.id][n.id] > child.diff_score
              child.parent = n
              closest.children.delete_if{|child_i| child_i == child }
              n.children << child
              child.diff_score = @similarity_matrix[child.id][n.id]
            end
          end

          # connect the new node to the parent
          n.parent = closest.parent
          n.parent.children << n
          n.diff_score = @similarity_matrix[n.id][n.parent.id]

          # add the existing node as a child
          closest.parent = n
          n.parent.children.delete_if{|child_i| child_i == closest}
          n.children << closest
          closest.diff_score = @similarity_matrix[closest.id][n.id]
        end

        flat << n
      end
      prune(flat)
    end

    # prune away nodes that don't meet the configured score threshold
    def prune(nodes)
      nodes.each do |node|
        node.parent.children.reject!{|n| n == node} if (node != @root) && (node.diff_score < @score_threshold)
      end
    end
  end
end