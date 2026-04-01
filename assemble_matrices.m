% assemble_matrices.m

% Builds M, C and K matrices

function [M, C, K] = assemble_matrices(L, J, M_shelf, m_printer, zeta, k)

% assemble M (diagonal matrix with Mtotal)
M = eye(L) * (M_shelf + m_printer * J);

% assemble C and K using local assemble_tridiagonal func
c_array = 2*zeta*sqrt(k * (M_shelf + m_printer)) * ones(1, L);
k_array = k * ones(1, L);
C = assemble_tridiagonal(c_array);
K = assemble_tridiagonal(k_array);

end

function matrix = assemble_tridiagonal(values)

main_diagonal = values + [values(2:end), 0];
sub_diagonal = -1 * values(2:end);

matrix = diag(main_diagonal, 0) + diag(sub_diagonal, 1) + diag(sub_diagonal, -1);

end