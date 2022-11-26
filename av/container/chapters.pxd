from av.chapter cimport Chapter


cdef class ChapterContainer(object):

    cdef list _chapters

    cdef add_chapter(self, Chapter chapter)
