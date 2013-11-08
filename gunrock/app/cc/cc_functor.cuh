#pragma once

#include <gunrock/app/problem_base.cuh>
#include <gunrock/app/cc/cc_problem.cuh>

namespace gunrock {
namespace app {
namespace cc {

template<typename VertexId, typename SizeT, typename Value, typename ProblemData>
struct UpdateMaskFunctor
{
    typedef typename ProblemData::DataSlice DataSlice;

    static __device__ __forceinline__ bool CondVertex(VertexId node, DataSlice *problem)
    {
        return true;
    }

    static __device__ __forceinline__ void ApplyVertex(VertexId node, DataSlice *problem)
    {
        VertexId parent;
        util::io::ModifiedLoad<ProblemData::COLUMN_READ_MODIFIER>::Ld(
                parent, problem->d_component_ids + node);
        util::io::ModifiedStore<ProblemData::QUEUE_WRITE_MODIFIER>::St(
                (parent == node)?0:1, problem->d_masks + node);
    }
};

template<typename VertexId, typename SizeT, typename Value, typename ProblemData>
struct HookMinFunctor
{
    typedef typename ProblemData::DataSlice DataSlice;

    static __device__ __forceinline__ bool CondVertex(VertexId node, DataSlice *problem)
    {
        bool mark;
        util::io::ModifiedLoad<ProblemData::COLUMN_READ_MODIFIER>::Ld(
                mark, problem->d_marks + node);
        return !mark;
    }

    static __device__ __forceinline__ void ApplyVertex(VertexId node, DataSlice *problem)
    {
        VertexId from_node;
        util::io::ModifiedLoad<ProblemData::COLUMN_READ_MODIFIER>::Ld(
                from_node, problem->d_froms + node);
        VertexId to_node;
        util::io::ModifiedLoad<ProblemData::COLUMN_READ_MODIFIER>::Ld(
                to_node, problem->d_tos + node);
        VertexId parent_from;
        util::io::ModifiedLoad<ProblemData::COLUMN_READ_MODIFIER>::Ld(
                parent_from, problem->d_component_ids + from_node);
        VertexId parent_to;
        util::io::ModifiedLoad<ProblemData::COLUMN_READ_MODIFIER>::Ld(
                parent_to, problem->d_component_ids + to_node);

        VertexId max_node = parent_from > parent_to ? parent_from : parent_to;
        VertexId min_node = parent_from + parent_to - max_node;
        if (max_node == min_node)
            util::io::ModifiedStore<ProblemData::QUEUE_WRITE_MODIFIER>::St(
            true, problem->d_marks + node);
        else
            util::io::ModifiedStore<ProblemData::QUEUE_WRITE_MODIFIER>::St(
            max_node, problem->d_component_ids + min_node);
    }
};

template<typename VertexId, typename SizeT, typename Value, typename ProblemData>
struct HookMaxFunctor
{
    typedef typename ProblemData::DataSlice DataSlice;

    static __device__ __forceinline__ bool CondVertex(VertexId node, DataSlice *problem)
    {
        bool mark;
        util::io::ModifiedLoad<ProblemData::COLUMN_READ_MODIFIER>::Ld(
                mark, problem->d_marks + node);
        return !mark;
    }

    static __device__ __forceinline__ void ApplyVertex(VertexId node, DataSlice *problem)
    {
        VertexId from_node;
        util::io::ModifiedLoad<ProblemData::COLUMN_READ_MODIFIER>::Ld(
                from_node, problem->d_froms + node);
        VertexId to_node;
        util::io::ModifiedLoad<ProblemData::COLUMN_READ_MODIFIER>::Ld(
                to_node, problem->d_tos + node);
        VertexId parent_from;
        util::io::ModifiedLoad<ProblemData::COLUMN_READ_MODIFIER>::Ld(
                parent_from, problem->d_component_ids + from_node);
        VertexId parent_to;
        util::io::ModifiedLoad<ProblemData::COLUMN_READ_MODIFIER>::Ld(
                parent_to, problem->d_component_ids + to_node);

        VertexId max_node = parent_from > parent_to ? parent_from : parent_to;
        VertexId min_node = parent_from + parent_to - max_node;
        if (max_node == min_node)
            util::io::ModifiedStore<ProblemData::QUEUE_WRITE_MODIFIER>::St(
            true, problem->d_marks + node);
        else
            util::io::ModifiedStore<ProblemData::QUEUE_WRITE_MODIFIER>::St(
            min_node, problem->d_component_ids + max_node);
    }
};

template<typename VertexId, typename SizeT, typename Value, typename ProblemData>
struct PtrJumpFunctor
{
    typedef typename ProblemData::DataSlice DataSlice;

    static __device__ __forceinline__ bool CondVertex(VertexId node, DataSlice *problem)
    {
        VertexId parent;
        util::io::ModifiedLoad<ProblemData::COLUMN_READ_MODIFIER>::Ld(
                parent, problem->d_component_ids + node);
        VertexId grand_parent;
        util::io::ModifiedLoad<ProblemData::COLUMN_READ_MODIFIER>::Ld(
                grand_parent, problem->d_component_ids + parent);
        return (parent != grand_parent);
    }

    static __device__ __forceinline__ void ApplyVertex(VertexId node, DataSlice *problem)
    { 
        VertexId parent;
        util::io::ModifiedLoad<ProblemData::COLUMN_READ_MODIFIER>::Ld(
                parent, problem->d_component_ids + node);
        VertexId grand_parent;
        util::io::ModifiedLoad<ProblemData::COLUMN_READ_MODIFIER>::Ld(
                grand_parent, problem->d_component_ids + parent);
        util::io::ModifiedStore<ProblemData::QUEUE_WRITE_MODIFIER>::St(
                grand_parent, problem->d_component_ids + node);
    }
};

template<typename VertexId, typename SizeT, typename Value, typename ProblemData>
struct PtrJumpMaskFunctor
{
    typedef typename ProblemData::DataSlice DataSlice;

    static __device__ __forceinline__ bool CondVertex(VertexId node, DataSlice *problem)
    {
        VertexId mask;
        util::io::ModifiedLoad<ProblemData::COLUMN_READ_MODIFIER>::Ld(
                mask, problem->d_masks + node);
        return mask == 0;
    }

    static __device__ __forceinline__ void ApplyVertex(VertexId node, DataSlice *problem)
    {
        VertexId parent;
        util::io::ModifiedLoad<ProblemData::COLUMN_READ_MODIFIER>::Ld(
                parent, problem->d_component_ids + node);
        VertexId grand_parent;
        util::io::ModifiedLoad<ProblemData::COLUMN_READ_MODIFIER>::Ld(
                grand_parent, problem->d_component_ids + parent);
        if (parent != grand_parent)
            util::io::ModifiedStore<ProblemData::QUEUE_WRITE_MODIFIER>::St(
            grand_parent, problem->d_component_ids + node);
        else
            util::io::ModifiedStore<ProblemData::QUEUE_WRITE_MODIFIER>::St(
            -1, problem->d_masks + node);
    }
};

template<typename VertexId, typename SizeT, typename Value, typename ProblemData>
struct PtrJumpUnmaskFunctor
{
    typedef typename ProblemData::DataSlice DataSlice;

    static __device__ __forceinline__ bool CondVertex(VertexId node, DataSlice *problem)
    {
        VertexId mask;
        util::io::ModifiedLoad<ProblemData::COLUMN_READ_MODIFIER>::Ld(
                mask, problem->d_masks + node);
        return mask == 1;
    }

    static __device__ __forceinline__ void ApplyVertex(VertexId node, DataSlice *problem)
    {
        VertexId parent;
        util::io::ModifiedLoad<ProblemData::COLUMN_READ_MODIFIER>::Ld(
                parent, problem->d_component_ids + node);
        VertexId grand_parent;
        util::io::ModifiedLoad<ProblemData::COLUMN_READ_MODIFIER>::Ld(
                grand_parent, problem->d_component_ids + parent);
        util::io::ModifiedStore<ProblemData::QUEUE_WRITE_MODIFIER>::St(
                grand_parent, problem->d_component_ids + node);
    }
};

} // cc
} // app
} // gunrock

// Leave this at the end of the file
// Local Variables:
// mode:c++
// c-file-style: "NVIDIA"
// End:
