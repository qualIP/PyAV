
cimport libav as lib


def _flatten(input_):
    for x in input_:
        if isinstance(x, (tuple, list)):
            for y in _flatten(x):
                yield y
        else:
            yield x


cdef class ChapterContainer(object):

    """

    A tuple-like container of :class:`Chapter`.

    ::

        # Access chapters like a list:
        first = container.chapters[0]

    """

    def __cinit__(self):
        self._chapters = []

    cdef add_chapter(self, Chapter chapter):
        self._chapters.append(chapter)

    # Basic tuple interface.
    def __len__(self):
        return len(self._chapters)

    def __iter__(self):
        return iter(self._chapters)

    def __getitem__(self, index):
        return self._chapters[index]
