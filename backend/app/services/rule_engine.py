from typing import Any, Dict, List, Optional
from app.schemas.recommendation import RuleEvaluationResult


class RuleEngine:
    """
    Deterministic generic hard-rule evaluator.
    Evaluates individual scheme rules and collections of rules against a normalized profile snapshot.
    Supports operators: equals, not_equals, >, >=, <, <=, in, not_in, contains, contains_any, contains_all, between, exists.
    """

    OPERATORS = {
        "equals", "==", "eq",
        "not_equals", "!=", "neq",
        ">", "gt",
        ">=", "gte",
        "<", "lt",
        "<=", "lte",
        "in",
        "not_in",
        "contains",
        "contains_any",
        "contains_all",
        "between",
        "exists",
    }

    @classmethod
    def evaluate_rule(
        cls,
        rule: Dict[str, Any],
        profile: Dict[str, Any],
    ) -> RuleEvaluationResult:
        rule_id = str(rule.get("id") or "")
        field_name = rule.get("field_name", "")
        raw_op = str(rule.get("operator", "equals")).strip().lower()
        expected = rule.get("expected_value")
        is_mandatory = bool(rule.get("is_mandatory", True))
        rule_type = str(rule.get("rule_type", "eligibility"))
        error_msg = str(rule.get("error_message") or f"Condition for {field_name} not satisfied.")

        actual = profile.get(field_name)

        # Missing information check
        if actual is None:
            return RuleEvaluationResult(
                rule_id=rule_id,
                field_name=field_name,
                operator=raw_op,
                expected_value=expected,
                actual_value=None,
                passed=False,
                is_mandatory=is_mandatory,
                rule_type=rule_type,
                error_message=f"Missing required information for '{field_name}'.",
                description=f"Information on '{field_name}' is needed to evaluate {rule_type}.",
            )

        passed = cls._execute_operator(raw_op, actual, expected)

        desc = (
            f"Rule '{field_name} {raw_op} {expected}' satisfied (actual: {actual})."
            if passed
            else error_msg
        )

        return RuleEvaluationResult(
            rule_id=rule_id,
            field_name=field_name,
            operator=raw_op,
            expected_value=expected,
            actual_value=actual,
            passed=passed,
            is_mandatory=is_mandatory,
            rule_type=rule_type,
            error_message=error_msg if not passed else None,
            description=desc,
        )

    @classmethod
    def _execute_operator(cls, op: str, actual: Any, expected: Any) -> bool:
        try:
            # 1. Equality & Negation
            if op in ["equals", "==", "eq"]:
                if isinstance(actual, str) and isinstance(expected, str):
                    return actual.strip().lower() == expected.strip().lower()
                return actual == expected

            if op in ["not_equals", "!=", "neq"]:
                if isinstance(actual, str) and isinstance(expected, str):
                    return actual.strip().lower() != expected.strip().lower()
                return actual != expected

            # 2. Relational Comparisons
            if op in [">", "gt"]:
                return float(actual) > float(expected)

            if op in [">=", "gte"]:
                return float(actual) >= float(expected)

            if op in ["<", "lt"]:
                return float(actual) < float(expected)

            if op in ["<=", "lte"]:
                return float(actual) <= float(expected)

            # 3. Inclusion & Set Membership
            if op == "in":
                # Check if actual is in expected list/set, or if actual (list) has any overlap with expected
                if isinstance(expected, (list, tuple, set)):
                    exp_norm = [str(x).strip().lower() for x in expected]
                    if isinstance(actual, (list, tuple, set)):
                        act_norm = [str(x).strip().lower() for x in actual]
                        return any(item in exp_norm for item in act_norm)
                    return str(actual).strip().lower() in exp_norm
                return str(actual).strip().lower() in str(expected).strip().lower()

            if op == "not_in":
                if isinstance(expected, (list, tuple, set)):
                    exp_norm = [str(x).strip().lower() for x in expected]
                    if isinstance(actual, (list, tuple, set)):
                        act_norm = [str(x).strip().lower() for x in actual]
                        return not any(item in exp_norm for item in act_norm)
                    return str(actual).strip().lower() not in exp_norm
                return str(actual).strip().lower() not in str(expected).strip().lower()

            # 4. Collection Checks
            if op == "contains":
                if isinstance(actual, (list, tuple, set)):
                    act_norm = [str(x).strip().lower() for x in actual]
                    return str(expected).strip().lower() in act_norm
                return str(expected).strip().lower() in str(actual).strip().lower()

            if op == "contains_any":
                if isinstance(actual, (list, tuple, set)) and isinstance(expected, (list, tuple, set)):
                    act_norm = {str(x).strip().lower() for x in actual}
                    exp_norm = {str(x).strip().lower() for x in expected}
                    return bool(act_norm & exp_norm)
                return False

            if op == "contains_all":
                if isinstance(actual, (list, tuple, set)) and isinstance(expected, (list, tuple, set)):
                    act_norm = {str(x).strip().lower() for x in actual}
                    exp_norm = {str(x).strip().lower() for x in expected}
                    return exp_norm.issubset(act_norm)
                return False

            # 5. Range Interval Check
            if op == "between":
                if isinstance(expected, (list, tuple)) and len(expected) == 2:
                    min_val = float(expected[0])
                    max_val = float(expected[1])
                    return min_val <= float(actual) <= max_val
                return False

            # 6. Existence Check
            if op == "exists":
                if expected is True or str(expected).lower() == "true":
                    return actual is not None and (actual != "" if isinstance(actual, str) else True)
                return actual is None

        except (ValueError, TypeError):
            return False

        return False
