require "./gdbm"

# TODO: Write documentation for `Nib`
module Nib
    VERSION = "0.1.0"

    PATH = ENV.fetch "NIB_PATH", File.expand_path "~/.nib/"
    Dir.mkdir_p PATH
    DB_PATH = ENV.fetch "NIB_DB", File.expand_path "~/.nib.db"


    def self.tag_files (files = [] of String, tags = [] of String)
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

    def self.tag_file (path : String, tags = [] of String)
        tag_files([ path ], tags)
    end

    def self.files_with_tags (tags)
        db = GDBM.new DB_PATH

        tags.reduce([] of String) do |acc, tag|
            acc + db["tag-files-#{tag}"].split ", "
        end.uniq!
    end

    def self.all_files
        db = GDBM.new DB_PATH

        res = [] of String
        db.each do |k, v|
            next unless k.starts_with? "tag-files"
            res.concat v.split ", "
        end
        res.uniq
    end

    def self.reindex
        files = [] of String
        db = GDBM.new DB_PATH

        # clean up any dead files
        db.each do |k, v|
            if k.starts_with? "tag-files"
                files = v.split(", ").select { |p| File.exists? p }
                db[k] = files.join ", "
            elsif k.starts_with? "file-tags"
                _, _, path = k.partition "file-tags-"
                next if File.exists? path

                db.delete k
            end
        end
    end
end
