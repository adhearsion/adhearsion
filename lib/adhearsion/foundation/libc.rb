# encoding: utf-8

require 'adhearsion/linux_proc_name'
require 'ffi'

module LibC
  extend FFI::Library
  ffi_lib FFI::Library::LIBC

  begin
    attach_function :prctl, [ :ulong, :ulong, :ulong, :ulong ], :int
  rescue FFI::NotFoundError => ex
    Adhearsion::LinuxProcName.error = "Error while attaching libc function prctl: #{ex}"
  end
end
