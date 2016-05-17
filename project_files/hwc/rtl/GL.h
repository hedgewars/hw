#pragma once

#if defined(__APPLE__) && !defined(EMSCRIPTEN)
#include <OpenGL/gl.h>
#else
#include "GL/gl.h"
#endif

/* emscripten cannot find these functions */
#ifdef EMSCRIPTEN
void glGetProgramInfoLog(GLuint program, GLsizei maxLength, GLsizei *length, GLchar *infoLog);
void glLinkProgram(GLuint program);
void glUniform1i(GLint location, GLint v0);
GLuint glCreateProgram(void);
void glUseProgram(GLuint program);
void glDeleteProgram(GLuint program);
void glGetProgramiv(GLuint program, GLenum pname, GLint *params);
void glDeleteShader(GLuint shader);
void glBindAttribLocation(GLuint program, GLuint index, const GLchar *name);
void glAttachShader(GLuint program, GLuint shader);
void glBindBuffer(GLenum target, GLuint buffer);
void glUniformMatrix4fv(GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glEnableVertexAttribArray(GLuint index);
void glDisableVertexAttribArray(GLuint index);
void glGenBuffers(GLsizei n, GLuint * buffers);
void glDeleteBuffers(GLsizei n, const GLuint * buffers);
void glUniform4fv(GLint location, GLsizei count, const GLfloat *value);
void glVertexAttribPointer(GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid * pointer);
void glBufferData(GLenum target, GLsizeiptr size, const GLvoid * data, GLenum usage);
void glUniform4f(GLint location, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3);
GLint glGetUniformLocation(GLuint program, const GLchar *name);
void glGetShaderInfoLog(GLuint shader, GLsizei maxLength, GLsizei *length, GLchar *infoLog);
void glGetShaderiv(GLuint shader, GLenum pname, GLint *params);
GLuint glCreateShader(GLenum shaderType);
void glCompileShader(GLuint shader);
void glShaderSource(GLuint shader, GLsizei count,/* const dropped for pas2c compat */ GLchar **string, const GLint *length);
#endif
