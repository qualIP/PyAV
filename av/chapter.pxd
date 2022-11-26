cimport libav as lib

from av.container.core cimport Container


cdef class Chapter(object):

    # Chapter attributes.
    cdef readonly Container container

    cdef lib.AVChapter *_chapter
    cdef readonly dict metadata

    # Private API.
    cdef _init(self, Container, lib.AVChapter*)
    cdef _finalize_for_output(self)


cdef Chapter wrap_chapter(Container, lib.AVChapter*)
