import pytest
from app.schemas.finance import FinancialSimulationInput
from app.services.financial_engine import FinancialEngine


def test_calculate_emi_standard():
    # 1 Lakh at 10% for 12 months
    emi = FinancialEngine.calculate_emi(principal=100000.0, annual_rate_pct=10.0, tenure_months=12)
    assert emi == 8791.59


def test_calculate_emi_zero_interest():
    # 60,000 at 0% for 12 months -> 5,000/mo
    emi = FinancialEngine.calculate_emi(principal=60000.0, annual_rate_pct=0.0, tenure_months=12)
    assert emi == 5000.0


def test_calculate_emi_zero_principal():
    emi = FinancialEngine.calculate_emi(principal=0.0, annual_rate_pct=10.0, tenure_months=12)
    assert emi == 0.0


def test_financial_simulation_safe_case():
    input_data = FinancialSimulationInput(
        total_project_cost=200000.0,
        own_capital=50000.0,  # Loan needed: 1,50,000
        annual_interest_rate_pct=9.5,
        tenure_months=24,
        projected_monthly_revenue=50000.0,
        projected_monthly_operating_cost=20000.0,  # Monthly profit: 30,000
    )
    result = FinancialEngine.simulate(input_data)
    assert result.required_loan_amount == 150000.0
    assert result.monthly_emi > 0
    assert result.is_affordable is True
    assert result.affordability_risk_level == "safe"
    assert result.debt_service_coverage_ratio > 1.25


def test_financial_simulation_critical_loss():
    # Revenue doesn't cover operating cost
    input_data = FinancialSimulationInput(
        total_project_cost=100000.0,
        own_capital=20000.0,
        annual_interest_rate_pct=10.0,
        tenure_months=12,
        projected_monthly_revenue=15000.0,
        projected_monthly_operating_cost=20000.0,  # Loss of 5,000
    )
    result = FinancialEngine.simulate(input_data)
    assert result.is_affordable is False
    assert result.affordability_risk_level == "critical"
