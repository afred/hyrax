module Hyrax
  class PermissionBadge
    include ActionView::Helpers::TagHelper

    # @param visibility [String] the current visibility
    def initialize(visibility)
      @visibility = visibility
    end

    # Draws a span tag with styles for a bootstrap label
    def render
      content_tag(:span, text, class: "label #{dom_label_class}")
    end

    private

      def dom_label_class
        I18n.t("hyrax.visibility.#{@visibility}.class")
      end

      def text
        if registered?
          Institution.name
        else
          I18n.t("hyrax.visibility.#{@visibility}.text")
        end
      end

      def registered?
        @visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      end
  end
end
