import pytest
from app.services.rule_engine import RuleEngine


def test_rule_engine_operators_numeric():
    profile = {"age": 25, "project_cost": 250000.0, "experience_years": 3.5}

    # >= operator
    rule_gte = {"field_name": "age", "operator": ">=", "expected_value": 18, "is_mandatory": True}
    res = RuleEngine.evaluate_rule(rule_gte, profile)
    assert res.passed is True
    assert res.actual_value == 25

    # > operator
    rule_gt = {"field_name": "age", "operator": ">", "expected_value": 30, "is_mandatory": True}
    res = RuleEngine.evaluate_rule(rule_gt, profile)
    assert res.passed is False

    # <= operator
    rule_lte = {"field_name": "project_cost", "operator": "<=", "expected_value": 5000000.0, "is_mandatory": True}
    res = RuleEngine.evaluate_rule(rule_lte, profile)
    assert res.passed is True

    # < operator
    rule_lt = {"field_name": "project_cost", "operator": "<", "expected_value": 100000.0, "is_mandatory": True}
    res = RuleEngine.evaluate_rule(rule_lt, profile)
    assert res.passed is False


def test_rule_engine_operators_equality_and_negation():
    profile = {"business_status": "new", "rural_or_urban": "rural", "previous_subsidy": False}

    # equals
    rule_eq = {"field_name": "business_status", "operator": "equals", "expected_value": "new"}
    res = RuleEngine.evaluate_rule(rule_eq, profile)
    assert res.passed is True

    # not_equals
    rule_neq = {"field_name": "rural_or_urban", "operator": "not_equals", "expected_value": "urban"}
    res = RuleEngine.evaluate_rule(rule_neq, profile)
    assert res.passed is True

    # Boolean equality
    rule_bool = {"field_name": "previous_subsidy", "operator": "equals", "expected_value": False}
    res = RuleEngine.evaluate_rule(rule_bool, profile)
    assert res.passed is True


def test_rule_engine_operators_in_and_not_in():
    profile = {"social_category": "sc", "target_category": ["sc", "woman"]}

    # in with string actual and list expected
    rule_in = {"field_name": "social_category", "operator": "in", "expected_value": ["sc", "st", "obc"]}
    res = RuleEngine.evaluate_rule(rule_in, profile)
    assert res.passed is True

    # in with list actual and list expected (set overlap)
    rule_in_list = {"field_name": "target_category", "operator": "in", "expected_value": ["st", "woman"]}
    res = RuleEngine.evaluate_rule(rule_in_list, profile)
    assert res.passed is True

    # not_in
    rule_not_in = {"field_name": "social_category", "operator": "not_in", "expected_value": ["general", "other"]}
    res = RuleEngine.evaluate_rule(rule_not_in, profile)
    assert res.passed is True


def test_rule_engine_operators_between():
    profile = {"loan_required": 350000.0}

    rule_between = {"field_name": "loan_required", "operator": "between", "expected_value": [50001, 500000]}
    res = RuleEngine.evaluate_rule(rule_between, profile)
    assert res.passed is True

    rule_outside = {"field_name": "loan_required", "operator": "between", "expected_value": [500001, 1000000]}
    res = RuleEngine.evaluate_rule(rule_outside, profile)
    assert res.passed is False


def test_rule_engine_operators_contains_and_exists():
    profile = {"skills": ["machinery", "welding", "packaging"], "description": "Cold-press mustard oil expeller unit"}

    rule_contains = {"field_name": "skills", "operator": "contains", "expected_value": "welding"}
    res = RuleEngine.evaluate_rule(rule_contains, profile)
    assert res.passed is True

    rule_contains_any = {"field_name": "skills", "operator": "contains_any", "expected_value": ["carpentry", "machinery"]}
    res = RuleEngine.evaluate_rule(rule_contains_any, profile)
    assert res.passed is True

    rule_contains_all = {"field_name": "skills", "operator": "contains_all", "expected_value": ["machinery", "welding"]}
    res = RuleEngine.evaluate_rule(rule_contains_all, profile)
    assert res.passed is True

    rule_exists = {"field_name": "description", "operator": "exists", "expected_value": True}
    res = RuleEngine.evaluate_rule(rule_exists, profile)
    assert res.passed is True


def test_rule_engine_missing_information_handling():
    # Profile lacks the age attribute
    profile = {"business_status": "new"}

    rule_age = {"field_name": "age", "operator": ">=", "expected_value": 18, "is_mandatory": True}
    res = RuleEngine.evaluate_rule(rule_age, profile)
    assert res.passed is False
    assert res.actual_value is None
    assert "Missing required information" in res.error_message
