@[Link("gdbm")]
lib LibGDBM
    type GDBMFile = Void*

        struct Datum
            dptr : LibC::Char*
                dsize : Int32
    end

    enum OpenFlags
        READER   = 0
        WRITER   = 1
        WRCREAT  = 2
        NEWDB    = 3
        OPENMASK = 7
        FAST     = 0x010
        SYNC     = 0x020
        NOLOCK   = 0x040
        NOMMAP   = 0x080
        CLOEXEC  = 0x100
        BSEXACT  = 0x200
        CLOERROR = 0x400
    end

    enum StoreFlags
        INSERT = 0
        REPLACE = 1
    end

    fun open      = gdbm_open(name : LibC::Char*, block_size : Int32, flags : Int32, mode : Int32, fatal_func : LibC::Char* -> Void) : GDBMFile
    fun close     = gdbm_close(db : GDBMFile)
    fun store     = gdbm_store(db : GDBMFile, key : Datum, content : Datum, flag : Int32)
    fun fetch     = gdbm_fetch(db : GDBMFile, key : Datum) : Datum
    fun delete    = gdbm_delete(db : GDBMFile, key : Datum)
    fun first_key = gdbm_firstkey(db : GDBMFile) : Datum
    fun next_key  = gdbm_nextkey(db : GDBMFile, key : Datum) : Datum
end

class Datum
    def self.from_s (str : String)
        LibGDBM::Datum.new(dptr: str, dsize: str.size)
    end
    def self.to_s (datum : LibGDBM::Datum)
        String.new(datum.dptr, datum.dsize)
    end
end

class GDBM
    def initialize(@filename : String, block_size = 512, flags = LibGDBM::OpenFlags::WRCREAT, mode = 0o777)
        @instance = LibGDBM.open(@filename, block_size, flags, mode, ->(x : LibC::Char*) {})
    end

    def []= (key, val)
        LibGDBM.store @instance, Datum.from_s(key), Datum.from_s(val), LibGDBM::StoreFlags::REPLACE
    end

    def [] (key)
        datum = LibGDBM.fetch @instance, Datum.from_s(key)
        raise KeyError.new(key) if datum.dptr.null?
        Datum.to_s datum
    end

    def []? (key)
        datum = LibGDBM.fetch @instance, Datum.from_s(key)

        return nil if datum.dptr.null?

        Datum.to_s datum
    end

    def each (&block)
        key = LibGDBM.first_key @instance
        while key.dptr.null? == false
            val = LibGDBM.fetch @instance, key
            yield Datum.to_s(key), Datum.to_s(val)
            key = LibGDBM.next_key @instance, key
        end
    end

    def delete (key)
        LibGDBM.delete @instance, Datum.from_s(key)
    end

    def close
        LibGDBM.close @instance
    end
end
