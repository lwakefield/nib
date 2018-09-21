require "dir"
require "file"
require "option_parser"
require "process"
require "uuid"

require "./gdbm"

DEFAULT_PATH = ENV.fetch "NIB_PATH", File.expand_path "~/.nib/"
Dir.mkdir_p DEFAULT_PATH
DB_PATH = ENV.fetch "NIB_DB", File.expand_path "~/.nib.db"

if ARGV.first? == "tag"
    parser = OptionParser.new
    tags = [] of String
    files = [] of String
    parser.on "-t <tag>", "Tag a file" { |t| tags << t }
    parser.unknown_args { |args| files.concat args }
    parser.parse ARGV[1..-1]

    files.map! { |f| File.expand_path f }

    tag_files files, tags
elsif ["ls", "cat"].includes? ARGV.first?
    parser = OptionParser.new
    tags = [] of String
    options = [] of String
    parser.invalid_option { |o| options << o }
    parser.unknown_args { |args| tags.concat args }
    parser.parse ARGV[1..-1]

    tags -= options

    # TODO default tags to _all_ tags if it is empty

    db = GDBM.new DB_PATH
    files = tags.reduce([] of String) do |acc, tag|
        acc += db["tag-files-#{tag}"].split ", "
    end.uniq!

    puts `#{ARGV.first} #{options.join " "} #{files.join " "}`
else
    parser = OptionParser.new
    tags = [] of String
    content = ""
    parser.on "-t <tag>", "Tag a file" { |t| tags << t }
    parser.unknown_args { |args| content = args.join " " }
    parser.parse ARGV

    path = File.join DEFAULT_PATH, UUID.random.to_s
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
        unless status.success?
            puts "error writing file"
            File.delete path
            exit(1)
        end
    else
        File.write path, content
    end

    tag_file path, tags
    puts "wrote to #{path}"
end

def tag_files (files = [] of String, tags = [] of String)
    db = GDBM.new DB_PATH

    files.each do |path|
        if t = db["file-tags-#{path}"]?
            db["file-tags-#{path}"] = t.split(", ").concat(tags).uniq.join ", "
        else
            db["file-tags-#{path}"] = tags.join ", "
        end
    end

    tags.each do |tag|
        if f = db["tag-files-#{tag}"]?
                db["tag-files-#{tag}"] = f.split(", ").concat(files).uniq.join ", "
        else
            db["tag-files-#{tag}"] = files.join ", "
        end
    end
end

def tag_file (path : String, tags = [] of String)
    tag_files([ path ], tags)
end

