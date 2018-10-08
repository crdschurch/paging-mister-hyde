Paging Mister Hyde
==========

[![Build Status](https://travis-ci.org/ample/paging-mister-hyde.svg?branch=master)](https://travis-ci.org/ample/paging-mister-hyde)

Pagination for [Jekyll](https://jekyllrb.com/) pages.

Usage
----------

You can paginate one or more collections, on a per-page basis, by defining a `paginate` object in template front-matter.

In the following example, the `articles` collection will be reduced to multiple pages containing `8` or fewer document instances:

```liquid
---
...
paginate:
  articles:
    per: 8
---
```

The pages will be generated dynamically according to the name of the template. For example, if the file described in the example above was named `articles.html` the paths for the generated pages would resolve to `/articles/page/2/index.html`, `/articles/page/3/index.html`, etc.

The paginated collections are exposed to the template via a `docs` collection on the `page.articles` object:

```liquid
{% for doc in page.articles.docs %}
  ...
{% endfor %}
```

In addition, there are several other data attributes attached to the page to help you build out pagination navigation, including:

- `total_pages`: Total number of pagination pages.
- `page`: Current page _number_.
- `previous_page`: Previous page number.
- `next_page`: Next page number.

### Offsetting Collections

The first `n` items can be extracted from the paginated collection by defining an `offset` number. This is helpful for exposing a certain number of _featured_ docs on the landing page of your collection. For example:

```liquid
---
...
paginate:
  articles:
    offset: 3
    per: 8
---
```

This would result in the first three items being attached to an `offset` array on the `page.articles` object:

```liquid
{{ page.articles.offset }}
```

And the remaining items would continue paginating as normal:

```liquid
{{ page.articles.docs }}
```

### Filtering Collections

Collections can be filtered (i.e. a _subset_ of the Jekyll collection) by adding a series of `where` arguments.

This works by using the `where` option within the pagination config and providing a series of key-value pairs where the key is the name of the attribute within the collection objects and the value is what that attribute must equal (or _contain_, more on that below).

For example, to only show articles where the title of the article is "My Title":

```liquid
---
...
paginate:
  articles:
    per: 8
    where:
      title: "My Title"
---
```

The paginator accepts more than one filter argument, but it will treat the filters as AND conditions, meaning both conditions must be true for the document to be presented in the collection.

```liquid
---
...
paginate:
  articles:
    per: 8
    where:
      title: "My Title"
      subtitle: "My Subtitle"
---
```

Filtering also supports dynamic values. Inspired by [ruby symbols](https://ruby-doc.org/core-2.2.0/Symbol.html), any value with a leading colon will look for that value in the data object of **the page** that is rendering the collection. For example:

```liquid
---
...
title: "Hello World"
paginate:
  articles:
    per: 8
    where:
      subtitle: :title
---
```

In that example, the only articles that would be returned in the collection would be those where their subtitle matched the title of the page rendering the collection (i.e. "Hello World").

Filtering also supports array fields and looks for only a single match. The paginator does this automatically. Let's say articles have tags via a `tags` field. And the current tag is the title of the page rendering the collection:

```liquid
---
...
paginate:
  articles:
    per: 8
    where:
      tags: :title
---
```

In this case, only those articles containing at least one tag matching the title of the page rendering the collection would be returned.

If the attribute to filter is an object (Hash) or an array of objects, use a period to chain together attributes, enabling the paginator to dig into the objects and match the correct value. Using the example above, suppose `tags` was an array of objects each containing a `title` key. To extract the correct value, the config would look like this:

```liquid
---
...
paginate:
  articles:
    per: 8
    where:
      tags.title: :title
---
```

### Sorting Collections

The paginator takes the collection as presented by Jekyll, but that can be overridden using the `sort`. The `sort` option takes two arguments, separated by a space. The first argument is the method by which to sort and the second is the sorting direction (`asc`/`desc`). The direction is optional and is `asc` by default.

For example, to sort articles in reverse chronological order, you could do something like this:

```liquid
---
...
paginate:
  articles:
    per: 8
    sort: date desc
---
```

But sorting articles by title could look like this:

```liquid
---
...
paginate:
  articles:
    per: 8
    sort: title
---
```

### Limiting Number of Pages Created

You can limit the first `n` pages from your paginated collection by defining a `limit` number. This is helpful if you'd like to show the first `n` pages without generating pages for the entire collection.

For example, to show the first 8 most recent articles and no additional pages:

```liquid
---
...
paginate:
  articles:
    per: 8
    limit: 1
---
```

### Merging Collections

The paginator will merge collections in the event you are combining multiple collections into a single array. This is done via the `collections` option, which takes an array of collection names:

```liquid
---
...
paginate:
  my_collection:
    collections:
      - articles
      - videos
    per: 8
---
```

In this case the name of the collection (`my_collection`) can be value and is still the method by which we access the docs:

```liquid
{{ page.my_collection.docs }}
```

Sorting and filtering still apply to merged collections, assuming the data field exists on each doc within all applicable collections.

License
----------

This project is licensed under the [3-Clause BSD License](https://opensource.org/licenses/BSD-3-Clause).
