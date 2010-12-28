#pragma once

#include "color.hpp"
#include "clipper.hpp"
#include "../std/shared_ptr.hpp"
#include "../geometry/point2d.hpp"
#include "../geometry/rect2d.hpp"

class ScreenBase;

namespace yg
{
  namespace gl
  {
    class BaseTexture;
    class VertexBuffer;
    class IndexBuffer;

    class Blitter : public Clipper
    {
    protected:

      typedef Clipper base_t;

      void setupAuxVertexLayout(bool hasColor, bool hasTexture);

    public:

      Blitter(base_t::Params const & params);

      void beginFrame();
      void endFrame();

      /// Immediate mode rendering functions.
      /// they doesn't buffer any data as other functions do, but immediately renders it
      /// @{

      void blit(shared_ptr<BaseTexture> const & srcSurface,
                ScreenBase const & from,
                ScreenBase const & to,
                yg::Color const & color,
                m2::RectI const & srcRect,
                m2::RectU const & texRect);

      void blit(shared_ptr<BaseTexture> const & srcSurface,
                ScreenBase const & from,
                ScreenBase const & to);

      void immDrawSolidRect(m2::RectF const & rect,
                            yg::Color const & color);

      void immDrawRect(m2::RectF const & rect,
                       m2::RectF const & texRect,
                       shared_ptr<BaseTexture> texture,
                       bool hasTexture,
                       yg::Color const & color,
                       bool hasColor);

      void immDrawTexturedPrimitives(m2::PointF const * pts,
                                     m2::PointF const * texPts,
                                     size_t size,
                                     shared_ptr<BaseTexture> const & texture,
                                     bool hasTexture,
                                     yg::Color const & color,
                                     bool hasColor);

      void immDrawTexturedRect(m2::RectF const & rect,
                               m2::RectF const & texRect,
                               shared_ptr<BaseTexture> const & texture);

      /// @}
    };
  }
}
