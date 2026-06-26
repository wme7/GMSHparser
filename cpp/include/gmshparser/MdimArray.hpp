#ifndef MULTI_DIMENSIONAL_ARRAY_HPP
#define MULTI_DIMENSIONAL_ARRAY_HPP

#include <vector>
#include <iostream>
#include <string>
#include <fstream>
#include <sstream>
#include <cmath>

/*
 * Multidimensionnal Array in C++ 
 * 
 * Original code by RM 
 * Modifications by MD
 * 
 * T: typename (int/size_t/float/double)
 * D: number of dimensions
 */

template<typename T, size_t D>
class MArray {

protected:
    T*   m_data;
    size_t m_total_size;
    size_t m_D;
    bool m_owned;
    bool m_allocated;
    std::vector<size_t> m_dims; // real dimensions

public:
    // Constructors & Destructor
    MArray():m_data(nullptr), m_total_size(0), m_D(D), m_owned(false), m_allocated(false) {}
    MArray(MArray const& Another)
    {
        //std::cout << "constructor by copy " << std::endl;
        m_total_size = Another.m_total_size;
        m_D = Another.m_D;
        m_dims = Another.m_dims;
        m_data = new T[m_total_size];
        // copy of the values from A to current array
        for(size_t i=0; i<m_total_size; i++)
        {
            m_data[i] = Another.m_data[i];
        }
        m_owned = true;
        m_allocated = true;
    }
    MArray(std::vector<size_t> const& dim)
    {
        //std::cout << "constructor by dim" << std::endl;
        m_D = D;
        m_total_size=1;
        for(size_t i=0; i<m_D; i++)
        {
           m_total_size *= dim[i];
           m_dims.push_back(dim[i]);
        }
        m_data = new T[m_total_size];
        m_allocated = true;
        m_owned = true;
    }
    MArray(std::vector<size_t> const& dim, T const val)
    {
        //std::cout << "constructor by dim with constant value" << std::endl;
        m_D = D;
        m_total_size=1;
        allocate(dim);
        for(size_t i=0;i<m_total_size;i++)
            {m_data[i] = val;}
    }
    MArray(std::vector<size_t> const& dim, std::vector<T> const& vec)
    {
        //std::cout << "constructor by dim with vector array" << std::endl;
        m_D = D;
        m_total_size=1;
        for (auto element : dim){ m_total_size *= element;}
        if (m_total_size==vec.size()) {
            allocate(dim);
            for(size_t i=0;i<m_total_size;i++) {
                m_data[i] = vec[i];
            }
        } else {
            std::cout<<"MArray and input vector have incompatible sizes" <<std::endl;
        }
    }
    ~MArray()
    {
        if (m_allocated==true && m_owned==true)
        {
            delete [] m_data;
            m_data = nullptr;
        }
        else
        {
            std::cout<<"MArray not allocated :P" <<std::endl; 
        }
    };

    // Operator overloading
    MArray& operator=(MArray other)
    {
        m_total_size = other.m_total_size;
        m_D = other.m_D;
        m_dims = other.m_dims;
        m_data = new T[m_total_size];
        // copy of the values from A to current array
        for(size_t i=0; i<m_total_size; i++)
        {
            m_data[i] = other.m_data[i];
        }
        m_owned = true;
        m_allocated = true;
        return *this;
    }

    T& operator()(size_t i) { return m_data[i]; }
    const T& operator()(size_t i) const { return m_data[i]; }
    T& operator()(size_t i, size_t j) { return m_data[i*m_dims[1]+j]; }
    const T& operator()(size_t i, size_t j) const {return m_data[i*m_dims[1]+j]; }
    T& operator()(size_t i, size_t j, size_t k) { return m_data[ i*m_dims[1]*m_dims[2]+j*m_dims[2]+k]; }
    const T& operator()(size_t i, size_t j, size_t k) const {return m_data[i*m_dims[1]*m_dims[2]+j*m_dims[2]+k]; }

    // Members functions that modify the data in the object
    void allocate(std::vector<size_t>const& dims2);
    void set_value(T val);    

    // Member functions that DO NOT modify the data in the object
    std::vector<size_t> dims() const{ return m_dims; }
    size_t total_size() const{ return m_total_size; }
    size_t N() const{ return m_D; }
    void print() const;
    T sum() const;
    T max() const;
    T min() const;
    T amax() const;
    T* data() const { return m_data; }
};

template<typename T, size_t D>
void MArray<T,D>::allocate(std::vector<size_t> const &dims2)
{
    m_dims = dims2;
    m_total_size = 1;
    for (auto element : dims2){ m_total_size *= element;}
    m_data = new T[m_total_size];
    m_allocated = true;
    m_owned = true;
}

template<typename T, size_t D>
void MArray<T,D>::set_value(T val)
{
    for (size_t i=0; i<m_total_size; i++) { m_data[i]=val; }
}

template<typename T, size_t D>
void MArray<T,D>::print() const
{
    if (m_allocated==1)
    {
        // Set print-out precision for 2D & 3D arrays
        std::cout.precision(4); // I need to check up to 8 decimals

        std::cout<<D<<"Darray:\n"<<std::endl;
        if(D==1)
        {
            // i-elements are printed as columns 
            for(size_t i=0; i<m_total_size; i++){
                std::cout << m_data[i] << std::endl;
            }
        }
        if(D==2 && m_dims.size()==2)
        {
            // i-elements are printed as columns 
            // j-elements are printed as rows
            for(size_t i=0; i<m_dims[0]; i++){ 
                for(size_t j=0; j<m_dims[1]; j++){
                    std::cout << m_data[i * m_dims[1] + j] << " " << std::scientific;
                } std::cout << std::endl;
            } std::cout << std::endl;
        }
        if(D==3 && m_dims.size()==3)
        {
            // i-elements are printed as columns 
            // j-elements are printed as rows
            // k-elements are printed as ij-arrays
            for(size_t k=0; k<m_dims[2]; k++){
                for(size_t i=0; i<m_dims[0]; i++){
                    for(size_t j=0; j<m_dims[1]; j++){
                        std::cout << m_data[i * m_dims[1]*m_dims[2] + j * m_dims[2] + k] << " " << std::scientific;
                    } std::cout << std::endl;
                } std::cout << std::endl;
            } std::cout << std::endl;
        }
    }
    else
    {
        std::cout<<"Marray not allocated\n" <<std::endl;   
    }
}

template<typename T, size_t D>
T MArray<T,D>::sum() const
{   T s=0;
    for (size_t i=0; i<m_total_size; i++) { s=s+m_data[i]; }
    return s;
}

template<typename T, size_t D>
T MArray<T,D>::max() const 
{   T s=-1e10;
    for (size_t i=0; i<m_total_size; i++) { s=std::max(m_data[i],s); }
    return s;
}

template<typename T, size_t D>
T MArray<T,D>::amax() const
{   T s=-1e10,s1;
    for (size_t i=0; i<m_total_size; i++) 
    {   s1 = std::abs(m_data[i]);
        s = std::max(s1,s); 
    }
    return s;
}

template<typename T, size_t D>
T MArray<T,D>::min() const
{   T s=1e10;
    for (size_t i=0; i<m_total_size; i++) { s=std::min(m_data[i],s); }
    return s;
}

#endif
