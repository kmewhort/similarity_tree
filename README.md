# SimilarityTree

This library allows you to generate a tree representing branches/revisions to a set of text HTML files, without any
prior knowledge of the timelines or change history necessary. You simply need to know the original source document and
this library builds a tree based on the extent of differences between each document.

## Installation

Add this line to your application's Gemfile:

    gem 'similarity_tree'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install similarity_tree

## Usage

Build a "similarity matrix" of the diff scores between the different documents, then generate the tree from this matrix.
First, build the "similarity matrix" of the diff scores between the different documents. You must input a set of HTML or
text documents.  Then, to build the tree itself, you need to specify the document id or filename of the original/root
document. Eg. for the set of different Creative Commons licences in the test dir:

    documents = Dir.glob('../../similarity_tree/test/cc_licences/*.html')
    tree = SimilarityTree::SimilarityMatrix.new(documents).build_tree("CC-BY-3.0.html")
    put tree.to_s  # to_h and to_json are also available as other tree output formats

Result:

    CC-BY-3.0.html
    -CC-BY-NC-3.0.html (0.9197574893009985)
    --CC-BY-NC-SA-3.0.html (0.9503146737330241)
    --CC-BY-NC-ND-3.0.html (0.9456402772710689)
    -CC-BY-ND-3.0.html (0.9434472109631346)

You can operate directly on **strings** rather than files (in this case, the node id's in the tree will be the file array indices):

    documents = Dir.glob('../../similarity_tree/test/cc_licences/*.html').map { |f| File.read(f) }
    tree = SimilarityTree::SimilarityMatrix.new(documents).build_tree("CC-BY-3.0.html")
    put tree.to_s  # to_h and to_json are also available as other tree output formats

Result:

    0
    -1 (0.9197574893009985)
    --3 (0.9503146737330241)
    --4 (0.9456402772710689)
    -2 (0.9434472109631346)

Or, you can use any **enumerable list of objects** (eg. ActiveRecords) as the inputs. Consider the model:

    class Document < ActiveRecord::Base
      attr_accessible :title, :text_filename
      ...
    end

Generate the tree as follows:

    tree = SimilarityTree::SimilarityMatrix.new(Document.all,
        id_func: :title, content_func: :text_filename).build_tree(Document.first.title)

## Additional Options

### Calculation method

You can use either the **term frequency–inverse document frequency** (:tf_idf, the default) or **Dice's coefficient** from a
standard unix-style diff to calculate the diff scores. Tf-idf works much better where a document has a lot of translations
(that is, "cut and pastes" of sections of text into different locations) and is often faster.  However, if your intent
is to show diffs of the text, the :diff option will correlate better to your diff rendering.

    tf_idf_tree = SimilarityTree::SimilarityMatrix.new(documents,
        calculation_method: :tf_idf).build_tree("CC-BY-3.0.html")
    diff_tree = SimilarityTree::SimilarityMatrix.new(documents,
        calculation_method: :diff).build_tree("CC-BY-3.0.html")

### Progress output

Performing all the diffs to build a similarity matrix can take a while for large document sets. If you're using this
gem from a script or a console, you can add a progress bar:

    tree = SimilarityTree::SimilarityMatrix.new(documents, show_progress: true).build_tree(id)

## Licence and Credits

(c) 2012-2013, Kent Mewhort (similarity tree) and Open North (original similarity_matrix implementation, see https://github.com/jpmckinney/clip-analysis),
licensed under MIT. See LICENSE.txt for details.