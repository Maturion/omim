#pragma once

#include "routing/base/graph.hpp"

#include "geometry/point2d.hpp"

#include "base/string_utils.hpp"

#include "std/vector.hpp"

namespace routing
{
class Route;

/// Defines position on a feature which represents a road with direction.
class RoadPos
{
public:
  // Our routers (such as a-star) use RoadPos as vertices and we receive PointD from the user.
  // Every time a route is calculated, we create a fake RoadPos with a fake featureId to
  // place the real starting point on it (and also do the same for the final point).
  // The constants here are used as those fake features' ids.
  /// @todo The constant value is taken to comply with an assert in the constructor
  ///       that is terrible, wrong and to be rewritten in a separate CL.
  static constexpr uint32_t kFakeStartFeatureId = (1U << 30) - 1;
  static constexpr uint32_t kFakeFinalFeatureId = (1U << 30) - 2;

  RoadPos() : m_featureId(0), m_segId(0), m_segEndpoint(0, 0) {}
  RoadPos(uint32_t featureId, bool forward, size_t segId,
          m2::PointD const & p = m2::PointD::Zero());

  uint32_t GetFeatureId() const { return m_featureId >> 1; }
  bool IsForward() const { return (m_featureId & 1) != 0; }
  uint32_t GetSegId() const { return m_segId; }
  uint32_t GetSegStartPointId() const { return m_segId + (IsForward() ? 0 : 1); }
  uint32_t GetSegEndPointId() const { return m_segId + (IsForward() ? 1 : 0); }
  m2::PointD const & GetSegEndpoint() const { return m_segEndpoint; }

  bool operator==(RoadPos const & r) const
  {
    return (m_featureId == r.m_featureId && m_segId == r.m_segId);
  }

  bool operator!=(RoadPos const & r) const
  {
    return (m_featureId != r.m_featureId || m_segId != r.m_segId);
  }

  bool operator<(RoadPos const & r) const
  {
    if (m_featureId != r.m_featureId)
      return m_featureId < r.m_featureId;
    if (m_segId != r.m_segId)
      return m_segId < r.m_segId;
    return false;
  }

private:
  friend string DebugPrint(RoadPos const & r);

  // Feature on which position is defined.
  uint32_t m_featureId;

  // Ordinal number of the segment on the road.
  uint32_t m_segId;

  // End-point of the segment on the road.
  m2::PointD m_segEndpoint;
};

/// The turn from the old to the new road.
struct PossibleTurn
{
  /// New road information.
  RoadPos m_pos;

  /// Start point on the old road.
  m2::PointD m_startPoint;

  /// End point on the old road.
  m2::PointD m_endPoint;

  /// Speed on the old road.
  double m_speedKMPH;

  /// Distance and time to get to this turn on old road.
  double m_metersCovered;
  double m_secondsCovered;

  PossibleTurn() : m_metersCovered(0.0), m_secondsCovered(0.0) {}
};

inline string DebugPrint(PossibleTurn const & r) { return DebugPrint(r.m_pos); }

class IRoadGraph
{
public:
  typedef vector<PossibleTurn> TurnsVectorT;
  typedef vector<RoadPos> RoadPosVectorT;
  typedef vector<m2::PointD> PointsVectorT;

  // This struct contains the part of a feature's metadata that is
  // relevant for routing.
  struct RoadInfo
  {
    RoadInfo() : m_speedKMPH(0.0), m_bidirectional(false) {}

    RoadInfo(RoadInfo const & ri)
        : m_points(ri.m_points), m_speedKMPH(ri.m_speedKMPH), m_bidirectional(ri.m_bidirectional)
    {
    }

    RoadInfo(RoadInfo && ri)
        : m_points(move(ri.m_points)),
          m_speedKMPH(ri.m_speedKMPH),
          m_bidirectional(ri.m_bidirectional)
    {
    }

    buffer_vector<m2::PointD, 32> m_points;
    double m_speedKMPH;
    bool m_bidirectional;
  };

  class CrossTurnsLoader
  {
  public:
    CrossTurnsLoader(m2::PointD const & cross, TurnsVectorT & turns);

    void operator()(uint32_t featureId, RoadInfo const & roadInfo);

  private:
    m2::PointD m_cross;
    TurnsVectorT & m_turns;
  };

  virtual ~IRoadGraph() = default;

  /// Construct route by road positions (doesn't include first and last section).
  void ReconstructPath(RoadPosVectorT const & positions, Route & route);

  /// Finds all nearest feature sections (turns), that route to the
  /// "pos" section.
  void GetNearestTurns(RoadPos const & pos, TurnsVectorT & turns);

  /// Adds fake turns from fake position rp to real vicinity
  /// positions.
  void SetFakeTurns(RoadPos const & rp, vector<RoadPos> const & vicinity);

protected:
  // Returns RoadInfo for a road corresponding to featureId.
  virtual RoadInfo GetRoadInfo(uint32_t featureId) = 0;

  // Returns speed in KM/H for a road corresponding to featureId.
  virtual double GetSpeedKMPH(uint32_t featureId) = 0;

  // Calls turnsLoader on each feature which is close to cross.
  virtual void ForEachClosestToCrossFeature(m2::PointD const & cross,
                                            CrossTurnsLoader & turnsLoader) = 0;

  // The way we find edges leading from start/final positions and from all other positions
  // differ: for start/final we find positions in some vicinity of the starting
  // point; for other positions we extract turns from the road graph. This non-uniformity
  // comes from the fact that a start/final position does not necessarily fall on a feature
  // (i.e. on a road).
  vector<PossibleTurn> m_startVicinityTurns;
  vector<PossibleTurn> m_finalVicinityTurns;
};

// A class which represents an edge used by RoadGraph.
struct RoadEdge
{
  RoadEdge(RoadPos const & target, double weight) : target(target), weight(weight) {}

  inline RoadPos const & GetTarget() const { return target; }

  inline double GetWeight() const { return weight; }

  RoadPos const target;
  double const weight;
};

// A wrapper around IGraph, which makes it possible to use IRoadGraph
// with routing algorithms.
class RoadGraph : public Graph<RoadPos, RoadEdge, RoadGraph>
{
public:
  RoadGraph(IRoadGraph & roadGraph);

private:
  friend class Graph<RoadPos, RoadEdge, RoadGraph>;

  // Graph<RoadPos, RoadEdge, RoadGraph> implementation:
  void GetAdjacencyListImpl(RoadPos const & v, vector<RoadEdge> & adj) const;
  double HeuristicCostEstimateImpl(RoadPos const & v, RoadPos const & w) const;

  IRoadGraph & m_roadGraph;
};

}  // namespace routing