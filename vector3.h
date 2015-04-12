#ifndef VECTOR3_H
#define VECTOR3_H

template <typename T>
class Vector3
{
    public:
        Vector3(T x, T y, T z)
        {
            setXYZ(x, y, z);
        }
        T x() { return m_data[0]; }
        T y() { return m_data[1]; }
        T z() { return m_data[2]; }
        void setXYZ(T x, T y, T z)
        {
            m_data[0] = x;
            m_data[1] = y;
            m_data[2] = z;
        }
    protected:
    private:
        T m_data[3];
};

typedef Vector3<float> Vector3F;
typedef Vector3<int> Vector3I;
typedef Vector3<double> Vector3D;

#endif // VECTOR3_H
