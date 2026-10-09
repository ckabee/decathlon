{% macro calculate_net_value(operation_column, value_column) %}
    case
        when lower({{ operation_column }}) = 'sale' then {{ value_column }}
        when lower({{ operation_column }}) = 'return' then -{{ value_column }}
        when lower({{ operation_column }}) = 'cancel' then 0
        else 0
    end
{% endmacro %}