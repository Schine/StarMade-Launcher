#ifndef VECTOR2_H
#define VECTOR2_H

template <typename T>
class Vector2
{
    public:
        Vector2(T x, T y)
        {
            setXY(x, y);
        }
        T x() { return m_data[0]; }
        T y() { return m_data[1]; }
        void setXY(T x, T y)
        {
            m_data[0] = x;
            m_data[1] = y;
        }
    protected:
    private:
        T m_data[2];
};

typedef Vector2<float> Vector2F;
typedef Vector2<int> Vector2I;
typedef Vector2<double> Vector2D;

#endif // VECTOR2_H
