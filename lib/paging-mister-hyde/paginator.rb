require 'active_support/core_ext/object/blank'

module PagingMisterHyde
  class Paginator

    attr_accessor :cfg, :page, :site

    def initialize(site, page)
      @site = site
      @page = page
      @cfg = page.data.dig('paginate')
      @cfg.keys.map do |type|
        offset_collection(type)
        pages = paginated_collection(type)
        decorate_page(@page, type, 1, pages.count, pages.first)
        paginate(type, pages)
      end unless @cfg.nil?
    end

    # For every collection in frontmatter
    # decorate the page with params needed in _pagination.html
    def decorate_page(page, type, page_num, total_pages, docs)
      attrs = {
        "docs" => docs,
        "total_pages" => total_pages,
        "page" => page_num,
        "previous_page" => previous_page_number(page_num),
        "next_page" => next_page_number(page_num, total_pages)
      }
      if page.data.keys.include?(type)
        page.data[type].merge!(attrs)
      else
        page.data[type] = attrs
      end
    end

    def paginate(type, collection)
      total_pages = collection.count

      if docs = collection[1..collection.count]
        # For each collection of docs...
        docs.each_with_index do |docs, i|

          # Set some things
          page_num = (i + 2)
          base = @page.instance_variable_get('@base')
          dir = @page.instance_variable_get('@dir')
          path = File.basename(@page.instance_variable_get('@path'))
          path_sans_ext = @page.url.chomp('/index.html').chomp('/')

          # Create a new page, set its URL to a paginable path
          page = Jekyll::Page.new(@site, base, dir, path)
          page.instance_variable_set('@url', "#{path_sans_ext}/page/#{page_num}/index.html")
          decorate_page(page, type, page_num, total_pages, docs)

          # Shovel the page
          @site.pages << page
        end
      end
    end

    protected

      def offset_collection(type)
        if n = @cfg.dig(type, 'offset')
          collection = filtered_and_sorted_collection(type)
          @page.data[type] = { "offset" => collection.take(n).to_a }
        end
      end

      def paginated_collection(type)
        collection = filtered_and_sorted_collection(type)
        return [[]] if collection.blank?
        collection_size = collection.is_a?(Array) ? collection.size : collection.try(:docs).try(:size)
        per = @cfg.dig(type, 'per') || collection_size
        limit = @cfg.dig(type, 'limit')
        offset = @cfg.dig(type, 'offset') || 0
        pages = collection.drop(offset).each_slice(per).to_a
        limit.nil? ? pages : pages.take(limit)
      end

      def filtered_and_sorted_collection(type)
        collection = if @page.data['paginate'][type]['collections']
          merge_collections(@page.data['paginate'][type]['collections'])
        else
          @site.collections[type].docs
        end
        collection = filter_collection(type, collection)
        sort_collection(type, collection)
      end

      def sort_collection(type, collection)
        if @cfg.dig(type, 'sort')
          sort_by, sort_in = @cfg.dig(type, 'sort') ? @cfg.dig(type, 'sort').split(' ') : nil
          collection = collection.sort_by { |d| d.data[sort_by] } if sort_by
          collection = collection.reverse if sort_in == 'desc'
        end
        collection
      end

      def filter_collection(type, collection)
        return collection unless cfg.dig(type, 'where')
        cfg.dig(type, 'where').each do |attr, value|
          value = page.data[value[1..-1]] if value.start_with?(':')
          collection = collection.select do |obj|
            obj.data[attr].is_a?(Array) ? obj.data[attr].include?(value) : obj.data[attr] == value
          end
        end
        collection
      end

      def merge_collections(types)
        collections = []
        types.each { |t| collections.concat(site.collections[t].docs) }
        collections
      end

      def previous_page_number(n)
        n > 1 ? n - 1 : false
      end

      def next_page_number(n, total)
        n < total ? n + 1 : false
      end
  end
end