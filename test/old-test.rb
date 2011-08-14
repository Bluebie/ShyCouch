require '~/dev/shycouch/shycouch'
require '~/dev/shycouch/shycouchtests'
require 'irb'

ShyCouchTests::test_up
ShyCouchTests::test_down
message = "Test methods: "
message += ShyCouchTests::singleton_methods.map { |m| "ShyCouchTests::#{m}"}.join(', ')
puts message
IRB.start