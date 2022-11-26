from av.utils cimport (
    avdict_to_dict,
    avrational_to_fraction,
    dict_to_avdict,
    to_avrational
)

cdef object _cinit_bypass_sentinel = object()



cdef Chapter wrap_chapter(Container container, lib.AVChapter *c_chapter):
    """Build an av.Chapter for an existing AVChapter.

    The AVChapter MUST be fully constructed and ready for use before this is
    called.

    """

    cdef Chapter py_chapter
    py_chapter = Chapter.__new__(Chapter, _cinit_bypass_sentinel)

    py_chapter._init(container, c_chapter)
    return py_chapter


cdef class Chapter(object):
    """
    A single chapter within a :class:`.Container`.
    """

    def __cinit__(self, name):
        if name is _cinit_bypass_sentinel:
            return
        raise RuntimeError('cannot manually instatiate Chapter')

    cdef _init(self, Container container, lib.AVChapter *chapter):

        self.container = container
        self._chapter = chapter

        self.metadata = avdict_to_dict(
            chapter.metadata,
            encoding=self.container.metadata_encoding,
            errors=self.container.metadata_errors,
        )

    def __repr__(self):
        return '<av.%s at 0x%x>' % (
            self.__class__.__name__,
            id(self),
        )

    cdef _finalize_for_output(self):

        dict_to_avdict(
            &self._chapter.metadata, self.metadata,
            encoding=self.container.metadata_encoding,
            errors=self.container.metadata_errors,
        )

        if not self._chapter.time_base.num:
            self._chapter.time_base = self._codec_context.time_base

    property time_base:
        """
        The unit of time (in fractional seconds) in which timestamps are expressed.

        :type: :class:`~fractions.Fraction` or ``None``

        """
        def __get__(self):
            return avrational_to_fraction(&self._chapter.time_base)

        def __set__(self, value):
            to_avrational(value, &self._chapter.time_base)
