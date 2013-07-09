
#ifndef WRAPPERS_H
#define WRAPPERS_H

#include "linalg.h"
#include <cmath>
#include <Eigen/Core>

static const double Pi = M_PI;
static const double oneOver16PiSqr = 1./(16. * M_PI * M_PI);

double Abs(double);
double Abs(const Complex&);
double AbsSqr(double);
double AbsSqr(const Complex&);

inline double AbsSqrt(double x)
{
   return std::sqrt(std::fabs(x));
}

double ArcTan(double);
double ArcSin(double);
double ArcCos(double);


inline double Conj(double a)
{
   return a;
}

inline Complex Conj(const Complex& a)
{
   return std::conj(a);
}

double Cos(double);
double Sin(double);

inline int Delta(int i, int j)
{
   return i == j;
}

Eigen::Matrix3d Diag(const Eigen::Matrix3d&);

void Diagonalize(const DoubleMatrix&, DoubleMatrix& , DoubleVector&);
void Diagonalize(const DoubleMatrix&, ComplexMatrix&, DoubleVector&);
void Diagonalize2by2(const DoubleMatrix&, DoubleMatrix& , DoubleVector&);
void Diagonalize2by2(const DoubleMatrix&, ComplexMatrix&, DoubleVector&);

// SVD
void Diagonalize(const DoubleMatrix&, DoubleMatrix& , DoubleMatrix& , DoubleVector&);
void Diagonalize(const DoubleMatrix&, ComplexMatrix&, ComplexMatrix&, DoubleVector&);
void Diagonalize2by2(const DoubleMatrix&, ComplexMatrix&, ComplexMatrix&, DoubleVector&);

inline double FiniteLog(double a)
{
   return a > std::numeric_limits<double>::epsilon() ? std::log(a) : 0;
}

inline double Log(double a)
{
   return std::log(a);
}

double MaxRelDiff(double, double);
double MaxRelDiff(const DoubleVector&, const DoubleVector&);

template <typename Base, typename Exponent>
double Power(Base base, Exponent exp)
{
   return std::pow(base, exp);
}


inline double Re(double x)
{
   return x;
}

double Re(const Complex&);

inline DoubleMatrix Re(const DoubleMatrix& m)
{
   return m;
}

DoubleMatrix Re(const ComplexMatrix&);

double Sqrt(double);

template <typename T>
T Sqr(T a)
{
   return a * a;
}

Eigen::ArrayXd ToEigenArray(const DoubleVector&);
DoubleVector ToDoubleVector(const Eigen::ArrayXd&);
Eigen::MatrixXd ToEigenMatrix(const DoubleMatrix&);
DoubleMatrix ToDoubleMatrix(const Eigen::MatrixXd&);

DoubleMatrix Transpose(const DoubleMatrix&);
ComplexMatrix Transpose(const ComplexMatrix&);

#define UNITMATRIX(rows) Eigen::Matrix<double,rows,rows>::Identity()

double ZeroSqrt(double);

#endif
