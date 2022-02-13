#ifndef TETRAHEDRON
#define TETRAHEDRON

#include <iostream>
#include "Node.hpp"

class Tetrahedron{
    /*
    ================================================================
    % ----------------- %
    % Tetrahedron class %
    % ----------------- %
        Describes an element by its four vertex ids, the global 
        identification number (id) and the element type.

    Implementation: MD
    ---------------  
    Input:
        ------
        Id (size_t) -> global indentification number,
        N1 (Node) -> first vertex id,
        N2 (Node) -> second vertex id
        N3 (Node) -> third vertex id,
        N4 (Node) -> fourth vertex id,
        ElementType (integer) -> element type.
        Partition (size_t) -> partition id
    ================================================================       
    */

private:
    size_t Id;
    Node<double> N1;
    Node<double> N2;
    Node<double> N3;
    Node<double> N4;
    int ElementType;
    size_t Partition;
    double Volume;

public:
    Tetrahedron(): Id(0), ElementType(-1), Partition(0), Volume(0.){}
    Tetrahedron(size_t Id_in, Node<double> N1_in, Node<double> N2_in, Node<double> N3_in, Node<double> N4_in, int ElementType_in, size_t Partition_in)
    {
        Id = Id_in;
        N1 = N1_in;
        N2 = N2_in;
        N3 = N3_in;
        N4 = N4_in;
        ElementType = ElementType_in;
        Partition = Partition_in;
        set_Volume();
    }
    // Member function that do modify the object
    void set_Volume() 
    {   // Dx = (cy-ay).*(dz-az) - (cz-az).*(dy-ay);           ax = N1.get_x;  bx = N2.get_x;  cx = N3.get_x;  dx = N4.get_x;
        // Dy = (cz-az).*(dx-ax) - (cx-ax).*(dz-az);   where:  ay = N1.get_y;  by = N2.get_y;  cy = N3.get_y;  dy = N4.get_y;
        // Dz = (cx-ax).*(dy-ay) - (cy-ay).*(dx-ax);           az = N1.get_z;  by = N2.get_z;  cz = N3.get_z;  dz = N4.get_z;
        // so that: Volume = ((bx-ax).*Dx + (by-ay).*Dy + (bz-az).*Dz) / 6;
        double Dx = (N3.get_y()-N1.get_y())*(N4.get_z()-N1.get_z()) - (N3.get_z()-N1.get_z())*(N4.get_y()-N1.get_y());
        double Dy = (N3.get_z()-N1.get_z())*(N4.get_x()-N1.get_x()) - (N3.get_x()-N1.get_x())*(N4.get_z()-N1.get_z());
        double Dz = (N3.get_x()-N1.get_x())*(N4.get_y()-N1.get_y()) - (N3.get_y()-N1.get_y())*(N4.get_x()-N1.get_x());
        Volume = 0.166666666666667*((N2.get_x()-N1.get_x())*Dx + (N2.get_y()-N1.get_y())*Dy + (N2.get_z()-N1.get_z())*Dz);
    }
    double testNodeOrder(const bool print)
    {   // If Volume is negative, re-order the nodes inside the element
        if (Volume<0)
        {   // SWAP nodes: EToV(i,:) = EToV(i,[1 2 4 3]);
            Node<double> Nt=N3; N3=N4; N4=Nt;
        }
        set_Volume(); if(print) std::cout << "element("<< Id <<").Volume= " << Volume << std::endl;
        return Volume;
    }
    // Member functions that do not modify the object
    size_t get_Id() const {return Id;}
    size_t get_N1Id() const {return N1.get_Id();}
    size_t get_N2Id() const {return N2.get_Id();}
    size_t get_N3Id() const {return N3.get_Id();}
    size_t get_N4Id() const {return N4.get_Id();}
    double get_N1x() const {return N1.get_x();}
    double get_N1y() const {return N1.get_y();}
    double get_N1z() const {return N1.get_z();}
    double get_N2x() const {return N2.get_x();}
    double get_N2y() const {return N2.get_y();}
    double get_N2z() const {return N2.get_z();}
    double get_N3x() const {return N3.get_x();}
    double get_N3y() const {return N3.get_y();}
    double get_N3z() const {return N3.get_z();}
    double get_N4x() const {return N4.get_x();}
    double get_N4y() const {return N4.get_y();}
    double get_N4z() const {return N4.get_z();}
    int get_ElementType() const {return ElementType;}
    size_t get_Partition() const {return Partition;}
    void print() const
    {
        std::cout << "Tetrahedron: " << Id << ", ElementType: " << ElementType << ", Partition: " << Partition << ", Volume: " << Volume << std::endl;
        std::cout << "\t"; N1.print();
        std::cout << "\t"; N2.print();
        std::cout << "\t"; N3.print();
        std::cout << "\t"; N4.print();
    }
};

#endif
