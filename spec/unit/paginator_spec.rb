require 'spec_helper'

describe PagingMisterHyde::Paginator do

  before do
    @base = File.expand_path('../dummy', __dir__)
    @site = JekyllHelper.scaffold(
      base_path: @base,
      collections_dir: File.join(@base, 'collections'),
      collections: %w(articles podcasts)
    )
  end

  context 'with a limit' do

    before do
      @page = Jekyll::Page.new(@site, @base, "", "articles.html")
      @page.data['paginate'] = {
        "articles" => {
          "limit" => 2,
          "per" => 1
        }
      }
      @paginator = PagingMisterHyde::Paginator.new(@site, @page)
    end

    it 'should only generate n pages' do
      pages = @site.pages.collect{|page| page if page.name == 'articles.html' }
      expect(pages.count).to eq(1)
    end

    it 'should reflect the correct number of total pages' do
      expect( @page.data.dig('articles', 'total_pages')).to eq(2)
    end
  end

  context 'with an offset' do
    before do
      @n = Random.rand(10)
      @total_docs = @site.collections['articles'].docs.count
      @page = Jekyll::Page.new(@site, @base, "", "articles.html")
      @page.data['paginate'] = {
        "articles" => {
          "offset" => @n,
          "sort" => "date desc",
          "per" => @total_docs
        }
      }
      @paginator = PagingMisterHyde::Paginator.new(@site, @page)
    end

    it 'should exclude the offset items from front of the pagination array' do
      offset = @page.data.dig('articles', 'offset')
      docs = @page.data.dig('articles', 'docs')
      expect(offset.count).to eq(@n)
      expect(docs.count).to eq(@total_docs - @n)

      offset_titles = offset.collect { |x| x.data['title'] }
      all_titles = docs.collect { |x| x.data['title'] }

      offset_titles.each do |title|
        expect(all_titles).to_not include(title)
      end
    end
  end

  context 'with an empty collection' do
    before do
      @page = Jekyll::Page.new(@site, @base, "", "articles.html")
      @page.data['paginate'] = { "songs" => { "per" => 10 } }
      @paginator = PagingMisterHyde::Paginator.new(@site, @page)
    end

    it 'returns an empty array for pages' do
      # binding.pry
      expect(@page.data.dig('songs', 'docs')).to eq([])
    end
  end

  context 'Articles' do
    before do
      @filename = "articles.html"
      @page = Jekyll::Page.new(@site, @base, "", @filename)
      @paginator = PagingMisterHyde::Paginator.new(@site, @page)
      @articles = @site.pages.select{|p| p.instance_variable_get('@name') == @filename }
    end

    it 'should paginate' do
      data = @page.data['articles']
      expect(data['docs']).to be_a(Array)
    end

    it 'should be configured to write the page(s) in the appropriate location(s)' do
      expect(@site.pages.collect(&:url)).to include("/articles.html/page/2/index.html")
    end

    it 'should sort articles in reverse chronological order' do
      data = @page.data['articles']['docs']
      dates = data.collect { |d| d.data['date'].to_i }
      per = @page.data.dig('paginate', 'articles', 'per')
      exp_dates = @site.collections['articles'].sort_by { |d| d.data['date'].to_i }.reverse.take(per).collect { |d| d.data['date'].to_i }
      expect(dates).to eq(exp_dates)
    end

    it 'should return previous page number' do
      expect(@paginator.send(:previous_page_number, 2)).to eq(1)
      expect(@paginator.send(:previous_page_number, 1)).to eq(false)
    end

    it 'should return next page number' do
      expect(@paginator.send(:next_page_number, 2, 3)).to eq(3)
      expect(@paginator.send(:next_page_number, 3, 3)).to eq(false)
    end

    context 'physical file' do
      it 'should be populated with values required by _pagination.html partial' do
        data = @page.data['articles']
        pagination_expectations(data)
      end
    end

    context 'dynamically generated file' do
      it 'should be populated with value required by _pagination.html partial' do
        @site.pages.each do |p|
          data = p.data['articles']
          pagination_expectations(data)
        end
      end
    end

  end

  context 'Podcasts' do

    it 'should sort podcasts by title' do
      pending
      @filename = 'podcasts.html'
      @page = Jekyll::Page.new(@site, @base, '', @filename)
      @paginator = PagingMisterHyde::Paginator.new(@site, @page)
      data = @page.data['podcasts']['docs']
      titles = data.collect { |d| d.data['title'] }
      exp_titles = @site.collections['podcasts'].sort_by { |d| d.data['title'] }.collect { |d| d.data['title'] }
      expect(titles).to eq(exp_titles)
    end
  end

  private

    def pagination_expectations(frontmatter)
      expect(frontmatter['total_pages']).to eq(@articles.count + 1)
      expect(frontmatter['page']).to be_instance_of(Integer)

      if frontmatter['page'] == 1
        expect(frontmatter['previous_page']).to be(false)
      else
        expect(frontmatter['previous_page']).to be_instance_of(Integer)
      end

      if frontmatter['page'] == @articles.count + 1
        expect(frontmatter['next_page']).to be(false)
      else
        expect(frontmatter['next_page']).to be_instance_of(Integer)
      end
    end

end
