/* Optional row order for the extracted lower-bound checker. The original
   DistQLDPC CC implementation uses seed-anchored reversed Tanner BFS (GH-183). */
#include <stdint.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

enum { max_dimension = 756 };

CAMLprim value caml_ccv_reverse_bfs(value width, value packed_rows) {
    CAMLparam2(width, packed_rows);
    CAMLlocal1(result);
    intnat n = Long_val(width);
    mlsize_t size = caml_string_length(packed_rows);
    if (n < 1 || n > max_dimension || size % (mlsize_t)n != 0 ||
        size / (mlsize_t)n > max_dimension) {
        CAMLreturn(Atom(0));
    }
    int cols = (int)n, rows = (int)(size / (mlsize_t)n);
    const unsigned char *matrix = Bytes_val(packed_rows);
    unsigned char visited_row[max_dimension] = {0}, visited_col[max_dimension] = {0};
    int order[max_dimension], head = 0, tail = 0;
    /* Starting at qubit zero fixes the first connected component. Restart
       from each unseen row so disconnected and empty rows are retained. */
    visited_col[0] = 1;
    for (int r = 0; r < rows; ++r) {
        if (matrix[r * cols]) {
            visited_row[r] = 1;
            order[tail++] = r;
        }
    }
    for (int start = -1; start < rows; ++start) {
        if (start >= 0 && !visited_row[start]) {
            visited_row[start] = 1;
            order[tail++] = start;
        }
        while (head < tail) {
            int current = order[head++];
            for (int q = 0; q < cols; ++q) {
                if (visited_col[q] || !matrix[current * cols + q]) continue;
                visited_col[q] = 1;
                for (int r = 0; r < rows; ++r) {
                    if (!visited_row[r] && matrix[r * cols + q]) {
                        visited_row[r] = 1;
                        order[tail++] = r;
                    }
                }
            }
        }
    }
    result = caml_alloc((mlsize_t)tail, 0);
    for (int i = 0; i < tail; ++i) Field(result,i) = Val_int(order[tail - 1 - i]);
    CAMLreturn(result);
}
