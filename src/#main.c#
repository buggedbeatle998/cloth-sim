#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include <string.h>
#include <stdint.h>
#include <time.h>

#include "../include/glad/glad.h"
#include <SDL3/SDL.h>
#include "../include/linmath.h"
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define SPEED 0.05f

static float rand_float(float lower, float upper) {
    return (float)rand() / RAND_MAX * (upper - lower) + lower;
}

typedef struct {
    uint x;
    uint y;
    uint z;
} dispindircmd;

typedef struct {
    uint count;
    uint inst_count;
    uint first;
    uint base_inst;
} drawarrindircmd;

typedef struct {
    vec3 pos;
    float rad;
} Sphere;

typedef struct {
    float data[6];
} Camera;

typedef struct {
    uint32_t res[2];
    vec2 inv_res;
    vec4 sun_dir;
    vec4 ground;
    vec4 horizon;
    vec3 zenith;
    float horz_dist;
    float fov;
    float asp_rat;
} push_consts;

static const float vertices[8] = {
    -1.f, -1.f,
    -1.f, 1.f,
    1.f, -1.f,
    1.f, 1.f,
};


GLuint load_shd(const char *filename, GLenum type, const char *entry);
void shd_loadatt(GLuint program, const char *filename, GLenum type, const char *entry);
GLuint make_draw_tex(const size_t tex_w, const size_t tex_h, GLenum texture);
GLuint make_buffer(GLenum type, GLenum usage, size_t size, const void *data);
uint8_t handle_keys(SDL_Event ev, uint8_t velo);
void handle_move(Camera *cam, uint8_t velo);

int main(void) {
    if (!SDL_Init(SDL_INIT_VIDEO))
        return -1;
   
    const size_t num_spheres = 10;
    Sphere *sphere_arr = malloc(sizeof(Sphere) * num_spheres);
    for (size_t i = 0; i < num_spheres; ++i) {
        sphere_arr[i] = (Sphere){{rand_float(-5.f, 5.f), rand_float(5.f, 15.f), rand_float(5.f, 15.f)}, 1.f};
    }
    Camera main_cam = {{0.f, 10.f, 0.f, 0.f, 0.f, 1.f}};
    
    const int tex_w = 1280;
    const int tex_h = 960;
    const int max_fps = 60;
    const float stpf = 1000.f / max_fps;

    SDL_Window *window = SDL_CreateWindow("Hello, World!", tex_w, tex_h, SDL_WINDOW_OPENGL);
    if (!window) {
        SDL_Quit();
        return -1;
    }
    SDL_Renderer *screen = SDL_CreateRenderer(window, "Hi");
    SDL_SetRenderVSync(screen, 1);

    SDL_GLContext context = SDL_GL_CreateContext(window);
    SDL_GL_MakeCurrent(window, context);
    SDL_GL_SetSwapInterval(1);
    gladLoadGLLoader((GLADloadproc)SDL_GL_GetProcAddress);
    
    GLuint vert_buff = make_buffer(GL_ARRAY_BUFFER, GL_STATIC_DRAW,
            sizeof(vertices), vertices);

    GLuint spheres = make_buffer(GL_SHADER_STORAGE_BUFFER, GL_STATIC_READ,
            sizeof(Sphere) * num_spheres, sphere_arr);
    free(sphere_arr);

    GLuint consts = make_buffer(GL_UNIFORM_BUFFER, GL_STATIC_READ,
            sizeof(push_consts), &(push_consts){
        {tex_w, tex_h             },
        {1.f/tex_w, 1.f/tex_h     },
        {0.f, 1.f, 0.f            ,0.f},
        {0.5f, 0.5f, 0.5f         ,0.f},
        {0.8f, 0.9f, 1.f          ,0.f},
        {0.5f, 0.5f, 1.f          },
        5000.f,
        1.047f,
        (float)tex_h / tex_w
    });

    make_buffer(GL_DISPATCH_INDIRECT_BUFFER, GL_STATIC_READ,
            sizeof(dispindircmd), &(dispindircmd){(tex_w + 31) / 32, (tex_h + 31) / 32, 1});
    
    make_buffer(GL_DRAW_INDIRECT_BUFFER, GL_STATIC_READ,
            sizeof(drawarrindircmd), &(drawarrindircmd){4, 1, 0, 0});

    GLuint ray_text = make_draw_tex(tex_w, tex_h, GL_TEXTURE0);
    
    const GLuint compute = glad_glCreateProgram();
    shd_loadatt(compute, "../shd/raytrace.comp.spv", GL_COMPUTE_SHADER, "main");
    glad_glLinkProgram(compute);

    const GLuint program = glad_glCreateProgram();
    shd_loadatt(program, "../shd/texture.vert.spv", GL_VERTEX_SHADER, "main");
    shd_loadatt(program, "../shd/texture.frag.spv", GL_FRAGMENT_SHADER, "main");
    glad_glLinkProgram(program);
    
    const GLint tex_loc = 0;
    const GLint vpos_loc = 0;
    const GLint cam_loc = 1;

    const GLint sphere_bind = 0;
    const GLint const_bind = 1;
    
    glad_glEnableVertexAttribArray(vpos_loc);
    glad_glVertexAttribPointer(vpos_loc, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 2, (void *)0);

    glad_glBindBufferBase(GL_SHADER_STORAGE_BUFFER, sphere_bind, spheres);
    glad_glBindBufferBase(GL_UNIFORM_BUFFER, const_bind, consts);
    
    glad_glUseProgram(compute);    
    glad_glUniform1i(tex_loc, 0);
    glad_glUseProgram(program);    
    glad_glUniform1i(tex_loc, 0);

    uint8_t velo = 0U;
    int width, height;
    bool run = true;
    while (run) {
        //time_t tstart = SDL_GetPerformanceCounter();

        SDL_Event ev;
        while (SDL_PollEvent(&ev)) {
            switch (ev.type) {
                case SDL_EVENT_QUIT:
                    run = false;
                    break;
                
                case SDL_EVENT_KEY_DOWN:
                case SDL_EVENT_KEY_UP:
                    velo = handle_keys(ev, velo);
                    break;

                default:
                    break;
            }
        }
        if (velo)
            handle_move(&main_cam, velo);

        SDL_RenderClear(screen);
        SDL_GetWindowSize(window, &width, &height);
        glad_glViewport(0, 0, width, height);

        glad_glUseProgram(compute);
        
        glad_glUniformMatrix2x3fv(cam_loc, 1, GL_FALSE, main_cam.data);
        glad_glDispatchComputeIndirect(0);
        
        glad_glMemoryBarrier(GL_SHADER_IMAGE_ACCESS_BARRIER_BIT);

        glad_glUseProgram(program);

        glad_glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glad_glDrawArraysIndirect(GL_TRIANGLE_STRIP, 0);
        
        SDL_RenderPresent(screen);

        SDL_GL_SwapWindow(window);

        //time_t tend = SDL_GetPerformanceCounter();
        //float telapsed = (float)(tend - tstart) / SDL_GetPerformanceFrequency() * 1000;
        //SDL_Delay(floor(stpf - telapsed));
    }
    
    glad_glDeleteProgram(program);
    glad_glDeleteTextures(1, &ray_text);
    glad_glDeleteBuffers(1, &vert_buff);
    SDL_DestroyRenderer(screen);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}


GLuint load_shd(const char *filename, GLenum type, const char *entry) {
    FILE *f = fopen(filename, "rb");
    fseek(f, 0, SEEK_END);
    const size_t len = ftell(f);
    fseek(f, 0, SEEK_SET);
    char *buff = malloc(len);
    fread(buff, len, 1, f);
    fclose(f);

    const GLuint shd = glad_glCreateShader(type);
    glad_glShaderBinary(1, &shd, GL_SHADER_BINARY_FORMAT_SPIR_V, (const void *)buff, len);
    glad_glSpecializeShader(shd, entry, 0, NULL, NULL);
    
    GLint compiled;
    glad_glGetShaderiv(shd, GL_COMPILE_STATUS, &compiled);
    if (compiled == GL_FALSE) {
        GLint shd_len;
        glad_glGetShaderiv(shd, GL_INFO_LOG_LENGTH, &shd_len);

        if (shd_len > 0) {
            GLchar *log = malloc(sizeof(GLchar) * shd_len);
            glad_glGetShaderInfoLog(shd, shd_len, &shd_len, log);
            free(log);
        }
    }
    free(buff);

    return shd;
}


void shd_loadatt(GLuint program, const char *filename, GLenum type, const char *entry) {
    const GLuint shd = load_shd(filename, type, entry);

    glad_glAttachShader(program, shd);

    glad_glDeleteShader(shd);
}


GLuint make_draw_tex(const size_t tex_w, const size_t tex_h, const GLenum texture) {
    GLuint tex;
    glad_glGenTextures(1, &tex);
    glad_glActiveTexture(texture);
    glad_glBindTexture(GL_TEXTURE_2D, tex);
    glad_glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glad_glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glad_glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, tex_w, tex_h, 0, GL_RGBA, GL_FLOAT, NULL);
    glad_glBindImageTexture(0, tex, 0, GL_FALSE, 0, GL_READ_WRITE, GL_RGBA32F);
    return tex;
}


GLuint make_buffer(GLenum type, GLenum usage, size_t size, const void *data) {
    GLuint buff;
    glad_glGenBuffers(1, &buff);
    glad_glBindBuffer(type, buff);
    glad_glBufferData(type, size, data, usage);
    
    return buff;
}


uint8_t handle_keys(SDL_Event ev, uint8_t velo) {
    switch (ev.key.key) {
        case SDLK_LEFT:
            velo &= ~1U;
            velo |= ev.key.down;
            break;
        case SDLK_RIGHT:
            velo &= ~(1U << 4);
            velo |= ev.key.down << 4;
            break;
        case SDLK_LSHIFT:
            velo &= ~(1U << 1);
            velo |= ev.key.down << 1;
            break;
        case SDLK_SPACE:
            velo &= ~(1U << 5);
            velo |= ev.key.down << 5;
            break;
        case SDLK_DOWN:
            velo &= ~(1U << 2);
            velo |= ev.key.down << 2;
            break;
        case SDLK_UP:
            velo &= ~(1U << 6);
            velo |= ev.key.down << 6;
            break;
        default:
            break;
    }

    return velo;
}


void handle_move(Camera *cam, uint8_t velo) {
    velo ^= velo >> 4;
    if (velo & 1) {
        cam->data[0] += (-0.5f + ((velo >> 4) & 1)) * SPEED;
    }
    velo >>= 1;
    if (velo & 1) {
        cam->data[1] += (-0.5f + ((velo >> 4) & 1)) * SPEED;
    }
    velo >>= 1;
    if (velo & 1) {
        cam->data[2] += (-0.5f + ((velo >> 4) & 1)) * SPEED;
    }
}
