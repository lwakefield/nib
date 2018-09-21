require "dir"
require "file"
require "option_parser"
require "process"
require "uuid"

require "./nib"

if ARGV.first? == "tag"
    parser = OptionParser.new
    tags = [] of String
    files = [] of String
    parser.on "-t <tag>", "Tag a file" { |t| tags << t }
    parser.unknown_args { |args| files.concat args }
    parser.parse ARGV[1..-1]

    files.map! { |f| File.expand_path f }

    Nib.tag_files files, tags
elsif ARGV.first? == "reindex"
    Nib.reindex
elsif ["ls", "cat"].includes? ARGV.first?
    parser = OptionParser.new
    tags = [] of String
    options = [] of String
    parser.invalid_option { |o| options << o }
    parser.unknown_args { |args| tags.concat args }
    parser.parse ARGV[1..-1]

    tags -= options

    files = tags.empty? ? Nib.all_files : Nib.files_with_tags tags

    puts `#{ARGV.first} #{options.join " "} #{files.join " "}`
else
    parser = OptionParser.new
    tags = [] of String
    last = false
    content = ""
    parser.on "-t <tag>", "Tag a file" { |t| tags << t }
    parser.on "--last", "Change the most recently modified matching file" { last = true}
    parser.unknown_args { |args| content = args.join " " }
    parser.parse ARGV

    if tags.empty?
        puts "please specify some tags"
        exit(1)
    end

    path = File.join Nib::PATH, UUID.random.to_s
    if content == ""
        editor = ENV.fetch "EDITOR", "vim"
        status = Process.run(
            editor,
            { path },
            shell: true,
            input: STDIN,
            output: STDOUT,
            error: STDERR
        )
        if status.success? == false
            puts "error writing file"
            File.delete path
            exit(1)
        end
        if File.exists?(path) == false || File.size(path) == 0
            puts "no content written"
            exit(1)
        end
    else
        File.write path, content
    end

    Nib.tag_file path, tags
    puts "wrote to #{path}"
end
