module ::Tiun::CoreHelper
   include ActionView::Helpers::TagHelper

   def react_component name, props = {}, options = {}, &block
      html_options = options.reverse_merge(data: {
         react_class: name,
         react_props: (props.is_a?(String) ? props : props.to_json)
      })
      content_tag(:div, '', html_options, &block)
   end
end

CoreHelper = ::Tiun::CoreHelper
