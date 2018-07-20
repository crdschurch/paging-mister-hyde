module PagingMisterHyde
  class Generator < Jekyll::Generator
    attr_accessor :site

    def generate(site)
      site.pages.
        select{|page| page.data.dig('paginate') }.
        map do |page|
          PagingMisterHyde::Paginator.new(site, page)
        end
    end
  end
end