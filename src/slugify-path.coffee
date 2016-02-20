slugify_path = (url_or_path) ->
  url_or_path
    .replace('/','')
    .replace(/\//g, '--')
    .replace(/,/g, '_')

module.exports = slugify_path
