function ds = response_schema(n_rows)
   ds = [array2table(nan(n_rows, 5), 'VariableNames', {'recalled', 'latency', 'FP', 'LP', 'advance'}), ...
         table(cellstr(repmat(char(0), n_rows, 1)), 'VariableNames', {'response'})];
end