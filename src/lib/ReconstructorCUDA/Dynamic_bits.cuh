/*
 * Dynamic_Bitset on GPU
 */
#pragma once
#include "CUDA_Error.cuh"


namespace SLS
{

/**
 * @brief A dynamic bitset array in GPU
 * This struct contains all required information of a dynamic array with `numElem` elements 
 * and each element contains `bitsPerElem` bits, 
 * as well as necessary **device** functions to manipulate bits in kernels.
 * Also there are two functions can be called in **host** code to query `numElem` and `bitsPerElem`.
 *
 * *Please note that this struct can only be generated by `GetGPUOBJ` function in a 
 * `Dynamic_Bitset_Array` object. `*bits` is a pointer to a GPU memory*
 */
struct Dynamic_Bitset_Array_GPU
{
    unsigned char* bits;
    size_t BITS_PER_BYTE;
    size_t numElem;
    size_t bitsPerElem;
    /* Set or clear a bit in uchar
     * position should be within BIT_PER_BYTE
     * http://stackoverflow.com/questions/47981/how-do-you-set-clear-and-toggle-a-single-bit-in-c-c
     */

    /**
     * @brief Set bit of a char to 1
     *
     * @param ch Char to operate
     * @param pos Position within the char
     */
    __device__ void setUChar(unsigned char& ch, const size_t &pos) { 
        ch |= 1<<pos; 
        //atomicOr( ch , 1<<pos);
    }
    /**
     * @brief Set bit of a char to 0
     *
     * @param ch Char to operate
     * @param pos Position within the char
     */
    __device__ void clearUChar(unsigned char& ch, const size_t &pos) { 
        ch &= ~(1<<pos);
        //atomicAnd(ch, ~(1<<pos));
    }

    /**
     * @brief Get bit of within a char
     *
     * @param ch Char to query
     * @param pos position of bit in char
     *
     * @return Ture if 1; otherwise, 0.
     */
    __device__ bool getUChar(const unsigned char& ch, const size_t &pos)const {return (ch>>pos)&1;}
    __device__ void setBit(const size_t &pos, const size_t &elem)
    {
        unsigned char *e = &bits[(elem * bitsPerElem)/BITS_PER_BYTE];
        setUChar( e[pos/BITS_PER_BYTE], pos%BITS_PER_BYTE);
    }
    __device__ void clearBit(const size_t &pos, const size_t &elem)
    {
        unsigned char *e = &bits[(elem * bitsPerElem)/BITS_PER_BYTE];
        clearUChar( e[pos/BITS_PER_BYTE], pos%BITS_PER_BYTE);
    }
    __device__ bool getBit(const size_t &pos, const size_t &elem) const
    {
        unsigned char *e = &bits[(elem * bitsPerElem)/BITS_PER_BYTE];
        return getUChar( e[pos/BITS_PER_BYTE], pos%BITS_PER_BYTE);
    }
    __device__ __host__ size_t getNumElem() const { return numElem;}
    __device__ __host__ size_t getBitsPerElem() const { return bitsPerElem;}
    __device__ unsigned int to_uint(const size_t &elem)
    {
        unsigned char *e = &bits[(elem * bitsPerElem)/BITS_PER_BYTE];
        unsigned int res = 0;
        for (size_t i=0; i<bitsPerElem/BITS_PER_BYTE; i++)
            res+= ( (unsigned int)e[i]<<(i*BITS_PER_BYTE));
        return res;
    }

};

class Dynamic_Bitset_Array{
private:
    unsigned char* bits;
    const size_t BITS_PER_BYTE;
    const size_t numElem;
    const size_t bitsPerElem;
public:
    Dynamic_Bitset_Array(size_t numberElements, size_t bitsPerElement): 
        BITS_PER_BYTE(8), 
        numElem(numberElements), 
        bitsPerElem(ceil((float)bitsPerElement/(float)BITS_PER_BYTE)*BITS_PER_BYTE)// Making sure integer nubmer of bytes
    {
        const size_t numBytes = (numElem * bitsPerElem + BITS_PER_BYTE -1)/BITS_PER_BYTE;
        gpuErrchk(cudaMalloc ((void**)&bits, numBytes));
        gpuErrchk(cudaMemset (bits, 0, numBytes));
    }
    ~Dynamic_Bitset_Array()
    {
        gpuErrchk( cudaFree(bits));
    }
    Dynamic_Bitset_Array_GPU getGPUOBJ() const  //Get an GPU object to process
    {
        Dynamic_Bitset_Array_GPU obj{bits, BITS_PER_BYTE, numElem, bitsPerElem};
        return obj;
    }
    bool writeToPGM( std::string fileName, size_t elemIdx ,const size_t &w, const size_t &h, bool transpose=false);
};
}
