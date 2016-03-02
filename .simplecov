SimpleCov.start do
  track_files '**/*.rb'

  add_filter '/spec'
  add_filter '/lib/actionizer/version'

  minimum_coverage 100.00
end
