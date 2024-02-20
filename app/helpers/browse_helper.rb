module BrowseHelper
  def element_single_current_link(type, object, url)
    link_to url, { :class => element_class(type, object), :title => element_title(object), :rel => (link_follow(object) if type == "node") } do
      element_strikethrough object do
        printable_element_name object
      end
    end
  end

  def element_list_item(type, object, &block)
    tag.li :class => element_class(type, object), :title => element_title(object) do
      element_strikethrough object, &block
    end
  end

  def printable_element_name(object)
    id = if object.id.is_a?(Array)
           object.id[0]
         else
           object.id
         end
    name = id.to_s

    # don't look at object tags if redacted, so as to avoid giving
    # away redacted version tag information.
    unless object.redacted?
      available_locales = Locale.list(name_locales(object))

      locale = available_locales.preferred(preferred_languages, :default => nil)

      if object.tags.include? "name:#{locale}"
        name = t "printable_name.with_name_html", :name => tag.bdi(object.tags["name:#{locale}"].to_s), :id => tag.bdi(name)
      elsif object.tags.include? "name"
        name = t "printable_name.with_name_html", :name => tag.bdi(object.tags["name"].to_s), :id => tag.bdi(name)
      elsif object.tags.include? "ref"
        name = t "printable_name.with_name_html", :name => tag.bdi(object.tags["ref"].to_s), :id => tag.bdi(name)
      end
    end

    name
  end

  def printable_element_version(object)
    t "printable_name.version", :version => object.version
  end

  def element_strikethrough(object, &block)
    if object.redacted? || !object.visible?
      tag.s(&block)
    else
      yield
    end
  end

  def element_class(type, object)
    classes = [type]
    classes += icon_tags(object).flatten.map { |t| h(t) } unless object.redacted?
    classes.join(" ")
  end

  def element_title(object)
    if object.redacted?
      ""
    else
      h(icon_tags(object).map { |k, v| "#{k}=#{v}" }.to_sentence)
    end
  end

  def link_follow(object)
    "nofollow" if object.tags.empty?
  end

  def type_and_paginated_count(type, pages)
    if pages.page_count == 1
      t "browse.changeset.#{type}",
        :count => pages.item_count
    else
      t "browse.changeset.#{type}_paginated",
        :x => pages.current_page.first_item,
        :y => pages.current_page.last_item,
        :count => pages.item_count
    end
  end

  private

  ICON_TAGS = %w[aeroway amenity barrier building highway historic landuse leisure man_made natural railway shop tourism waterway].freeze

  def icon_tags(object)
    object.tags.find_all { |k, _v| ICON_TAGS.include? k }.sort
  end

  def name_locales(object)
    object.tags.keys.map { |k| Regexp.last_match(1) if k =~ /^name:(.*)$/ }.flatten
  end
end
