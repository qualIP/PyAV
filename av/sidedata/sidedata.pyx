from av.enum cimport define_enum

from collections.abc import Mapping

from av.sidedata.motionvectors import MotionVectors


cdef object _cinit_bypass_sentinel = object()


Type = define_enum('Type', __name__, (
    ('PANSCAN', lib.AV_FRAME_DATA_PANSCAN),
    ('A53_CC', lib.AV_FRAME_DATA_A53_CC),
    ('STEREO3D', lib.AV_FRAME_DATA_STEREO3D),
    ('MATRIXENCODING', lib.AV_FRAME_DATA_MATRIXENCODING),
    ('DOWNMIX_INFO', lib.AV_FRAME_DATA_DOWNMIX_INFO),
    ('REPLAYGAIN', lib.AV_FRAME_DATA_REPLAYGAIN),
    ('DISPLAYMATRIX', lib.AV_FRAME_DATA_DISPLAYMATRIX),
    ('AFD', lib.AV_FRAME_DATA_AFD),
    ('MOTION_VECTORS', lib.AV_FRAME_DATA_MOTION_VECTORS),
    ('SKIP_SAMPLES', lib.AV_FRAME_DATA_SKIP_SAMPLES),
    ('AUDIO_SERVICE_TYPE', lib.AV_FRAME_DATA_AUDIO_SERVICE_TYPE),
    ('MASTERING_DISPLAY_METADATA', lib.AV_FRAME_DATA_MASTERING_DISPLAY_METADATA),
    ('GOP_TIMECODE', lib.AV_FRAME_DATA_GOP_TIMECODE),
    ('SPHERICAL', lib.AV_FRAME_DATA_SPHERICAL),
    ('CONTENT_LIGHT_LEVEL', lib.AV_FRAME_DATA_CONTENT_LIGHT_LEVEL),
    ('ICC_PROFILE', lib.AV_FRAME_DATA_ICC_PROFILE),
    # SEI_UNREGISTERED available since version 56.54.100 of libavutil (FFmpeg >= 4.4)
    ('SEI_UNREGISTERED', lib.AV_FRAME_DATA_SEI_UNREGISTERED) if lib.AV_FRAME_DATA_SEI_UNREGISTERED != -1 else None,

    # These are deprecated. See https://github.com/PyAV-Org/PyAV/issues/607
    # ('QP_TABLE_PROPERTIES', lib.AV_FRAME_DATA_QP_TABLE_PROPERTIES),
    # ('QP_TABLE_DATA', lib.AV_FRAME_DATA_QP_TABLE_DATA),

))


cdef SideData wrap_side_data(Frame frame, int index):

    cdef lib.AVFrameSideDataType type_ = frame.ptr.side_data[index].type
    if type_ == lib.AV_FRAME_DATA_MOTION_VECTORS:
        return MotionVectors(_cinit_bypass_sentinel, frame, index)
    else:
        return SideData(_cinit_bypass_sentinel, frame, index)


cdef class SideData(Buffer):

    def __init__(self, sentinel, Frame frame, int index):
        if sentinel is not _cinit_bypass_sentinel:
            raise RuntimeError('cannot manually instatiate SideData')
        self.frame = frame
        self.ptr = frame.ptr.side_data[index]
        self.metadata = wrap_dictionary(self.ptr.metadata)

    cdef size_t _buffer_size(self):
        return self.ptr.size

    cdef void* _buffer_ptr(self):
        return self.ptr.data

    cdef bint _buffer_writable(self):
        return False

    def __repr__(self):
        return f'<av.sidedata.{self.__class__.__name__} {self.ptr.size} bytes of {self.type} at 0x{<unsigned int>self.ptr.data:0x}>'

    @property
    def type(self):
        return Type.get(self.ptr.type) or self.ptr.type


cdef class _SideDataContainer(object):

    def __init__(self, Frame frame):

        self.frame = frame
        self._by_index = []
        self._by_type = {}

        cdef int i
        cdef SideData data
        for i in range(self.frame.ptr.nb_side_data):
            data = wrap_side_data(frame, i)
            self._by_index.append(data)
            self._by_type[data.type] = data

    def __len__(self):
        return len(self._by_index)

    def __iter__(self):
        return iter(self._by_index)

    def __getitem__(self, key):

        if isinstance(key, int):
            return self._by_index[key]

        type_ = Type.get(key)
        return self._by_type[type_]


class SideDataContainer(_SideDataContainer, Mapping):
    """SideDataContainer provides a Mapping-compatible interface.

    While _SideDataContainer is a sequence indexed by position,
    SideDataContainer is a full mapping with keys/items/values methods.
    However, contrary to usual mappings, SideDataContainer's default iterator
    is still by value.

    Design note: SideData types can be integers so they cannot be used as
    mapping keys since __getitem__ could not differentiate an integer key from
    a plain index. Therefore, the 0-based list index is used as mapping key.
    Still, SideDataContainer inherits _SideDataContainer's support for indexing
    by SideData type.
    """

    def keys(self):
        "D.keys() -> a set-like object providing a view on D's keys"
        return range(len(self))

    def items(self):
        "D.items() -> a set-like object providing a view on D's items"
        return enumerate(self._by_index)

    def values(self):
        "D.values() -> an object providing a view on D's values"
        return list(self._by_index)
