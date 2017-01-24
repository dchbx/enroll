arch = case RUBY_PLATFORM
  when /64.*linux/
    'linux-amd64'
  when /linux/
    'linux-x86'
  when /darwin/
    'darwin-x86_64'
  else
    raise "Invalid platform. Must be running linux or intel-based Mac OS."
end

executable_path = File.expand_path "#{File.dirname(Gem.bin_path('wkhtmltopdf-binary-edge'))}/../libexec/wkhtmltopdf-#{arch}"

WickedPdf.config = {
  exe_path: executable_path
}
