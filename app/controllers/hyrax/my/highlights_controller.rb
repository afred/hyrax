module Hyrax
  module My
    class HighlightsController < MyController
      def search_builder_class
        Hyrax::MyHighlightsSearchBuilder
      end

      def index
        super
      end

      protected

        def search_action_url(*args)
          hyrax.dashboard_highlights_url(*args)
        end

        def query_solr
          return empty_search_result if Hyrax::TrophyPresenter.find_by_user(@user).count.zero?
          super
        end

        def empty_search_result
          solr_response = Blacklight::Solr::Response.new(empty_request, {})
          docs = []
          [solr_response, docs]
        end

        def empty_request
          {
            responseHeader: {
              status: 0,
              params: { wt: 'ruby', rows: '11', q: '*:*' }
            },
            response: { numFound: 0, start: 0, docs: [] }
          }
        end
    end
  end
end
