#=
This is the place, where I put functions, which are so annoying in OpenGL, that I felt the need to wrap them and make them more "Julian"
Its also to do some more complex error handling, not handled by the debug callback
=#

function glGetShaderiv(shaderID::GLuint, variable::GLenum)
    result = Ref{GLint}(-1)
    glGetShaderiv(shaderID, variable, result)
    result[]
end
function glShaderSource(shaderID::GLuint, shadercode::Vector{UInt8})
    shader_code_ptrs = Ptr{UInt8}[pointer(shadercode)]
    len              = Ref{GLint}(length(shadercode))
    glShaderSource(shaderID, 1, shader_code_ptrs, len)
end
glShaderSource(shaderID::GLuint, shadercode::String) = glShaderSource(shaderID, Vector{UInt8}(shadercode))
function glGetAttachedShaders(program::GLuint)
    shader_count   = glGetProgramiv(program, GL_ATTACHED_SHADERS)
    length_written = GLsizei[0]
    shaders        = zeros(GLuint, shader_count)

    glGetAttachedShaders(program, shader_count, length_written, shaders)
    shaders[1:first(length_written)]
end

get_attribute_location(program::GLuint, name) = get_uniform_location(program, ascii(name))
get_attribute_location(program::GLuint, name::Symbol) = get_attribute_location(program, string(name))
function get_attribute_location(program::GLuint, name::Compat.ASCIIString)
    const location::GLint = glGetAttribLocation(program, name)
    if location == -1
        error(
            "Named attribute (:$(name)) is not an active attribute in the specified program object or\n
            the name starts with the reserved prefix gl_\n"
        )
    elseif location == GL_INVALID_OPERATION
        error(
            "program is not a value generated by OpenGL or\n
            program is not a program object or\n
            program has not been successfully linked"
        )
    end
    location
end
get_uniform_location(program::GLuint, name) = get_uniform_location(program, ascii(name))
get_uniform_location(program::GLuint, name::Symbol) = get_uniform_location(program, string(name))
function get_uniform_location(program::GLuint, name::Compat.ASCIIString)
    const location = glGetUniformLocation(program, name)::GLint
    if location == -1
        error(
            """Named uniform (:$(name)) is not an active attribute in the specified program object or
            the name starts with the reserved prefix gl_"""
        )
    elseif location == GL_INVALID_OPERATION
        error("""program is not a value generated by OpenGL or
            program is not a program object or
            program has not been successfully linked"""
        )
    end
    location
end

function glGetActiveUniform(programID::GLuint, index::Integer)
    actualLength   = GLsizei[1]
    uniformSize    = GLint[1]
    typ            = GLenum[1]
    maxcharsize    = glGetProgramiv(programID, GL_ACTIVE_UNIFORM_MAX_LENGTH)
    name           = Vector{GLchar}(maxcharsize)

    glGetActiveUniform(programID, index, maxcharsize, actualLength, uniformSize, typ, name)

    actualLength[1] <= 0 &&  error("No active uniform at given index. Index: ", index)

    uname = unsafe_string(pointer(name), actualLength[1])
    uname = Symbol(replace(uname, r"\[\d*\]", "")) # replace array brackets. This is not really a good solution.
    (uname, typ[1], uniformSize[1])
end
function glGetActiveAttrib(programID::GLuint, index::Integer)
    actualLength   = GLsizei[1]
    attributeSize  = GLint[1]
    typ            = GLenum[1]
    maxcharsize    = glGetProgramiv(programID, GL_ACTIVE_ATTRIBUTE_MAX_LENGTH)
    name           = Vector{GLchar}(maxcharsize)

    glGetActiveAttrib(programID, index, maxcharsize, actualLength, attributeSize, typ, name)

    actualLength[1] <= 0 && error("No active uniform at given index. Index: ", index)

    uname = unsafe_string(pointer(name), actualLength[1])
    uname = Symbol(replace(uname, r"\[\d*\]", "")) # replace array brackets. This is not really a good solution.
    (uname, typ[1], attributeSize[1])
end
function glGetProgramiv(programID::GLuint, variable::GLenum)
    result = Ref{GLint}(-1)
    glGetProgramiv(programID, variable, result)
    result[]
end
function glGetIntegerv(variable::GLenum)
    result = Ref{GLint}(-1)
    glGetIntegerv(UInt32(variable), result)
    result[]
end




function glGenBuffers(n=1)
    const result = GLuint[0]
    glGenBuffers(1, result)
    id = result[]
    if id <= 0
        error("glGenBuffers returned invalid id. OpenGL Context active?")
    end
    id
end
function glGenVertexArrays()
    const result = GLuint[0]
    glGenVertexArrays(1, result)
    id = result[1]
    if id <=0
        error("glGenVertexArrays returned invalid id. OpenGL Context active?")
    end
    id
end
function glGenTextures()
    const result = GLuint[0]
    glGenTextures(1, result)
    id = result[1]
    if id <= 0
        error("glGenTextures returned invalid id. OpenGL Context active?")
    end
    id
end
function glGenFramebuffers()
    const result = GLuint[0]
    glGenFramebuffers(1, result)
    id = result[1]
    if id <= 0
        error("glGenFramebuffers returned invalid id. OpenGL Context active?")
    end
    id
end

function glDeleteTextures(id::GLuint)
  arr = [id]
  glDeleteTextures(1, arr)
end
function glDeleteVertexArrays(id::GLuint)
  arr = [id]
  glDeleteVertexArrays(1, arr)
end
function glDeleteBuffers(id::GLuint)
  arr = [id]
  glDeleteBuffers(1, arr)
end

function glGetTexLevelParameteriv(target::GLenum, level, name::GLenum)
  result = GLint[0]
  glGetTexLevelParameteriv(target, level, name, result)
  result[1]
end

glViewport(x::SimpleRectangle) = glViewport(x.x, x.y, x.w, x.h)
glScissor(x::SimpleRectangle) = glScissor(x.x, x.y, x.w, x.h)


function glGenRenderbuffers(format::GLenum, attachment::GLenum, dimensions)
    renderbuffer = GLuint[0]
    glGenRenderbuffers(1, renderbuffer)
    glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer[1])
    glRenderbufferStorage(GL_RENDERBUFFER, format, dimensions...)
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, attachment, GL_RENDERBUFFER, renderbuffer[1])
    renderbuffer[1]
end


function glTexImage(ttype::GLenum, level::Integer, internalFormat::GLenum, w::Integer, h::Integer, d::Integer, border::Integer, format::GLenum, datatype::GLenum, data)
    glTexImage3D(GL_PROXY_TEXTURE_3D, level, internalFormat, w, h, d, border, format, datatype, C_NULL)
    for l in  0:level
        result = glGetTexLevelParameteriv(GL_PROXY_TEXTURE_3D, l, GL_TEXTURE_WIDTH)
        if result == 0
            error("glTexImage 3D: width too large. Width: ", w)
        end
        result = glGetTexLevelParameteriv(GL_PROXY_TEXTURE_3D, l,GL_TEXTURE_HEIGHT)
        if result == 0
            error("glTexImage 3D: height too large. height: ", h)
        end
        result = glGetTexLevelParameteriv(GL_PROXY_TEXTURE_3D, l, GL_TEXTURE_DEPTH)
        if result == 0
            error("glTexImage 3D: depth too large. Depth: ", d)
        end
        result = glGetTexLevelParameteriv(GL_PROXY_TEXTURE_3D, l, GL_TEXTURE_INTERNAL_FORMAT)
        if result == 0
            error("glTexImage 3D: internal format not valid. format: ", GLENUM(internalFormat).name)
        end
    end
    glTexImage3D(ttype, level, internalFormat, w, h, d, border, format, datatype, data)
end
function glTexImage(ttype::GLenum, level::Integer, internalFormat::GLenum, w::Integer, h::Integer, border::Integer, format::GLenum, datatype::GLenum, data)
    maxsize = glGetIntegerv(GL_MAX_TEXTURE_SIZE)
    glTexImage2D(GL_PROXY_TEXTURE_2D, level, internalFormat, w, h, border, format, datatype, C_NULL)
    for l in 0:level
        result = glGetTexLevelParameteriv(GL_PROXY_TEXTURE_2D, l, GL_TEXTURE_WIDTH)
        if result == 0
            error("glTexImage 2D: width too large. Width: ", w)
        end
        result = glGetTexLevelParameteriv(GL_PROXY_TEXTURE_2D, l, GL_TEXTURE_HEIGHT)
        if result == 0
            error("glTexImage 2D: height too large. height: ", h)
        end
        result = glGetTexLevelParameteriv(GL_PROXY_TEXTURE_2D, l, GL_TEXTURE_INTERNAL_FORMAT)
        if result == 0
            error("glTexImage 2D: internal format not valid. format: ", GLENUM(internalFormat).name)
        end
    end
    glTexImage2D(ttype, level, internalFormat, w, h, border, format, datatype, data)
end
function glTexImage(ttype::GLenum, level::Integer, internalFormat::GLenum, w::Integer, border::Integer, format::GLenum, datatype::GLenum, data)
    glTexImage1D(GL_PROXY_TEXTURE_1D, level, internalFormat, w, border, format, datatype, C_NULL)
    for l in 0:level
        result = glGetTexLevelParameteriv(GL_PROXY_TEXTURE_1D, l, GL_TEXTURE_WIDTH)
        if result == 0
            error("glTexImage 1D: width too large. Width: ", w)
        end
        result = glGetTexLevelParameteriv(GL_PROXY_TEXTURE_1D, l, GL_TEXTURE_INTERNAL_FORMAT)
        if result == 0
            error("glTexImage 1D: internal format not valid. format: ", GLENUM(internalFormat).name)
        end
    end
    glTexImage1D(ttype, level, internalFormat, w, border, format, datatype, data)
end
