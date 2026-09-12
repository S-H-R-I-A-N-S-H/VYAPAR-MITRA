import math
from typing import List
from app.schemas.finance import (
    AmortizationScheduleItem,
    FinancialSimulationInput,
    FinancialSimulationResult,
)


class FinancialEngine:
    """
    Authoritative deterministic financial calculation engine for Vyapar Mitra.
    Never delegates calculations to an LLM.
    """

    @staticmethod
    def calculate_emi(principal: float, annual_rate_pct: float, tenure_months: int) -> float:
        """Standard reducing balance EMI formula: P * r * (1 + r)^n / ((1 + r)^n - 1)"""
        if principal <= 0 or tenure_months <= 0:
            return 0.0

        if annual_rate_pct <= 0:
            return round(principal / tenure_months, 2)

        monthly_rate = (annual_rate_pct / 100.0) / 12.0
        factor = math.pow(1.0 + monthly_rate, tenure_months)
        emi = principal * monthly_rate * factor / (factor - 1.0)
        return round(emi, 2)

    @classmethod
    def generate_amortization_preview(
        cls, principal: float, annual_rate_pct: float, tenure_months: int, preview_months: int = 6
    ) -> List[AmortizationScheduleItem]:
        """Generates month-by-month repayment breakdown for preview."""
        items: List[AmortizationScheduleItem] = []
        if principal <= 0 or tenure_months <= 0:
            return items

        monthly_rate = (annual_rate_pct / 100.0) / 12.0
        emi = cls.calculate_emi(principal, annual_rate_pct, tenure_months)
        current_balance = principal

        limit = min(tenure_months, preview_months)
        for m in range(1, limit + 1):
            interest = round(current_balance * monthly_rate, 2) if annual_rate_pct > 0 else 0.0
            principal_paid = round(min(emi - interest, current_balance), 2)
            closing_balance = round(max(0.0, current_balance - principal_paid), 2)

            items.append(
                AmortizationScheduleItem(
                    month=m,
                    opening_balance=round(current_balance, 2),
                    emi=emi,
                    principal=principal_paid,
                    interest=interest,
                    closing_balance=closing_balance,
                )
            )
            current_balance = closing_balance
            if current_balance <= 0:
                break

        return items

    @classmethod
    def simulate(cls, data: FinancialSimulationInput) -> FinancialSimulationResult:
        """Evaluates complete project financing, cash flow, debt burden, and affordability."""
        # 1. Loan sizing
        required_loan = (
            data.loan_amount_requested
            if data.loan_amount_requested is not None
            else max(0.0, data.total_project_cost - data.own_capital)
        )

        # 2. Debt calculations
        monthly_emi = cls.calculate_emi(
            principal=required_loan,
            annual_rate_pct=data.annual_interest_rate_pct,
            tenure_months=data.tenure_months,
        )
        total_repayment = round(monthly_emi * data.tenure_months, 2)
        total_interest = round(max(0.0, total_repayment - required_loan), 2)

        # 3. Operational profitability
        monthly_profit = round(data.projected_monthly_revenue - data.projected_monthly_operating_cost, 2)
        net_cash_flow = round(monthly_profit - monthly_emi, 2)

        # 4. Debt Service Coverage Ratio (DSCR) = Operational Profit / EMI
        if monthly_emi > 0:
            dscr = round(monthly_profit / monthly_emi, 2)
        else:
            dscr = 99.0 if monthly_profit >= 0 else 0.0

        # 5. Affordability Evaluation
        if monthly_profit <= 0:
            is_affordable = False
            risk_level = "critical"
            rationale = "Projected operating revenue is insufficient to cover operating costs even before debt repayment."
        elif net_cash_flow < 0:
            is_affordable = False
            risk_level = "critical"
            rationale = f"Negative monthly net cash flow (₹{net_cash_flow:,.2f}). Monthly EMI (₹{monthly_emi:,.2f}) exceeds operating profit (₹{monthly_profit:,.2f})."
        elif dscr < 1.25:
            is_affordable = True
            risk_level = "moderate"
            rationale = f"Tight debt servicing margin (DSCR {dscr:.2f}). Cash flow can cover EMI, but unexpected cost surges could cause repayment pressure."
        else:
            is_affordable = True
            risk_level = "safe"
            rationale = f"Healthy debt coverage (DSCR {dscr:.2f}). Net surplus after EMI is ₹{net_cash_flow:,.2f} per month."

        amortization_preview = cls.generate_amortization_preview(
            principal=required_loan,
            annual_rate_pct=data.annual_interest_rate_pct,
            tenure_months=data.tenure_months,
            preview_months=6,
        )

        return FinancialSimulationResult(
            total_project_cost=data.total_project_cost,
            own_capital=data.own_capital,
            required_loan_amount=required_loan,
            monthly_emi=monthly_emi,
            total_interest_payable=total_interest,
            total_repayment_amount=total_repayment,
            projected_monthly_profit=monthly_profit,
            net_cash_flow_after_emi=net_cash_flow,
            debt_service_coverage_ratio=dscr,
            is_affordable=is_affordable,
            affordability_risk_level=risk_level,
            affordability_rationale=rationale,
            amortization_preview=amortization_preview,
        )
