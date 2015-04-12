#include "glutil.h"
#include <string>
#include <png.h>
#include <iostream>

GLuint GLUtil::loadTexture(std::string fileName, int *width, int *height)
{
    glEnable(GL_TEXTURE_2D);
    const int PNGSIGSIZE = 8;
    png_byte header[PNGSIGSIZE];

    FILE *fp = fopen(fileName.c_str(), "rb");
    if (fp == NULL)
    {
        std::cerr << "Failed to open texture: " << fileName.c_str() << std::endl;
        return 0;
    }

    fread(header, 1, PNGSIGSIZE, fp);

    if (png_sig_cmp(header, 0, PNGSIGSIZE) != 0)
    {
        std::cerr << fileName << " is not a PNG!" << std::endl;
        fclose(fp);
        return 0;
    }

    png_structp png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
    if (png_ptr == nullptr)
    {
        std::cerr << "png_create_read_struct returned null" << std::endl;
        fclose(fp);
        return 0;
    }

    png_infop info_ptr = png_create_info_struct(png_ptr);
    if (info_ptr == nullptr)
    {
        std::cerr << "png_create_info_struct returned null" << std::endl;
        png_destroy_read_struct(&png_ptr, (png_infopp)NULL, (png_infopp)NULL);
        fclose(fp);
        return 0;
    }

    png_infop end_info = png_create_info_struct(png_ptr);
    if (end_info == nullptr)
    {
        std::cerr << "png_create_info_struct returned null" << std::endl;
        png_destroy_read_struct(&png_ptr, &info_ptr, &end_info);
        fclose(fp);
        return 0;
    }

    if (setjmp(png_jmpbuf(png_ptr)))
    {
        std::cerr << "error from libpng" << std::endl;
        png_destroy_read_struct(&png_ptr, &info_ptr, &end_info);
        fclose(fp);
        return 0;
    }

    png_init_io(png_ptr, fp);

    png_set_sig_bytes(png_ptr, 8);

    png_read_info(png_ptr, info_ptr);

    int bit_depth;
    int color_type;
    png_uint_32 temp_width;
    png_uint_32 temp_height;

    png_get_IHDR(png_ptr, info_ptr, &temp_width, &temp_height, &bit_depth, &color_type, NULL, NULL, NULL);

    if (width != nullptr)
    {
        *width = temp_width;
    }
    if (height != nullptr)
    {
        *height = temp_height;
    }

    if (bit_depth != 8)
    {
        std::cerr << "Unsupported bit depth on file " << fileName << ". Must be 8." << std::endl;
        return 0;
    }

    GLint format;
    switch (color_type)
    {
    case PNG_COLOR_TYPE_RGB:
        format = GL_RGB;
        break;
    case PNG_COLOR_TYPE_RGB_ALPHA:
        format = GL_RGBA;
        break;
    default:
        std::cerr << "Unknown color type for file " << fileName << ". " << color_type << std::endl;
        break;
    }

    png_read_update_info(png_ptr, info_ptr);

    int rowbytes = png_get_rowbytes(png_ptr, info_ptr);

    rowbytes += 3 - ((rowbytes - 1 ) % 4);

    png_byte *image_data = (png_byte*)malloc(rowbytes * temp_height * sizeof(png_byte) + 15);
    if (image_data == nullptr)
    {
        std::cerr << "Could not allocate memory for PNG image data." << std::endl;
        png_destroy_read_struct(&png_ptr, &info_ptr, &end_info);
        fclose(fp);
        return 0;
    }

    png_byte **row_pointers = (png_byte**)malloc(temp_height * sizeof(png_byte*));
    if (row_pointers == nullptr)
    {
        std::cerr << "Could not allocated memory for PNG row pointers." << std::endl;
        png_destroy_read_struct(&png_ptr, &info_ptr, &end_info);
        free(image_data);
        fclose(fp);
        return 0;
    }

    for (unsigned int i = 0; i < temp_height; ++i)
    {
        row_pointers[temp_height - 1 - i] = image_data + i * rowbytes;
    }

    png_read_image(png_ptr, row_pointers);

    GLuint texture;
    glGenTextures(1, &texture);
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexImage2D(GL_TEXTURE_2D, 0, format, temp_width, temp_height, 0, format, GL_UNSIGNED_BYTE, image_data);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

    png_destroy_read_struct(&png_ptr, &info_ptr, &end_info);
    free(image_data);
    free(row_pointers);
    fclose(fp);
    return texture;
}
