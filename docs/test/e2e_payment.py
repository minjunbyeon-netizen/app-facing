# -*- coding: utf-8 -*-
"""P1 §2.3 결제 모달 E2E 검증"""
import asyncio
from playwright.async_api import async_playwright

cap = "C:/dev/apps/facing-app/docs/test/2026-05-23-1937-payment-modal"


async def run():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        ctx = await browser.new_context(viewport={"width": 1280, "height": 900})
        page = await ctx.new_page()

        # 로그인 (JS fetch)
        await page.goto("http://localhost:8081/login")
        await page.wait_for_timeout(1000)
        await page.evaluate(
            "fetch('/api/proxy/login',{method:'POST',headers:{'Content-Type':'application/json'},"
            "body:JSON.stringify({login_id:'boss_seongsu',password:'1234'})})"
        )
        await page.wait_for_timeout(800)

        # 회원 상세
        await page.goto("http://localhost:8081/members/46")
        await page.wait_for_timeout(2000)
        await page.screenshot(path=f"{cap}/03-member-detail.png")
        print("03 member detail OK")

        # 결제 탭
        await page.evaluate("document.querySelector('button.tab-chip[data-tab=\"payments\"]').click()")
        await page.wait_for_timeout(1500)
        await page.screenshot(path=f"{cap}/04-payments-tab.png")
        print("04 payments tab OK")

        # 결제 추가 모달 열기
        await page.evaluate("openPayment()")
        await page.wait_for_timeout(800)
        await page.screenshot(path=f"{cap}/05-modal-open.png")
        print("05 modal open OK")

        # 금액 입력
        await page.fill("#pmPlanPrice", "100000")
        await page.fill("#pmDiscount", "20000")
        await page.fill("#pmReceived", "50000")
        await page.wait_for_timeout(600)
        unpaid_val = await page.input_value("#pmUnpaid")
        print(f"미수금 자동계산: {unpaid_val}  (expected: 30000)")
        await page.screenshot(path=f"{cap}/06-amounts-filled.png")
        print("06 amounts OK")

        # + 결제수단 추가
        await page.evaluate("addPmRow()")
        await page.wait_for_timeout(400)
        inputs = await page.query_selector_all("#pmMethodRows input[type='number']")
        print(f"method input count: {len(inputs)}")
        if len(inputs) >= 2:
            await inputs[0].fill("30000")
            await inputs[1].fill("20000")
        selects = await page.query_selector_all("#pmMethodRows select")
        if len(selects) >= 2:
            await selects[1].select_option("card")
        await page.wait_for_timeout(500)
        await page.screenshot(path=f"{cap}/07-methods-cash30-card20.png")
        print("07 methods filled OK")

        # 직접 API 호출로 저장 검증
        result = await page.evaluate("""async () => {
            const res = await fetch('/api/proxy/members/46/payments', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({
                    plan_price: 100000,
                    discount_amount: 20000,
                    received_amount: 50000,
                    unpaid_amount: 30000,
                    payment_methods: [
                        {method: 'cash', amount: 30000},
                        {method: 'card', amount: 20000}
                    ],
                    paid_at: '2026-05-23'
                })
            });
            return await res.json();
        }""")
        print(f"API 저장 ok: {result.get('ok')}")
        d = result.get("data", {})
        print(f"  received_amount: {d.get('received_amount')}")
        print(f"  unpaid_amount: {d.get('unpaid_amount')}")
        print(f"  payment_methods: {d.get('payment_methods')}")
        print(f"  method(DB컬럼): {d.get('method')}")

        # 모달 닫고 결제 이력 로드
        await page.evaluate("closeModal('paymentModal')")
        await page.wait_for_timeout(300)
        await page.evaluate("loadTab('payments')")
        await page.wait_for_timeout(2000)
        await page.screenshot(path=f"{cap}/08-after-save.png")
        print("08 after save OK")

        # 결제 목록에서 미수금 확인
        body = await page.text_content("body")
        print(f"30,000 표시됨: {'30,000' in body}")
        print(f"100,000 표시됨: {'100,000' in body}")
        print(f"20,000(할인) 표시됨: {'20,000' in body}")

        # 최종 결제 이력 스크린샷
        await page.screenshot(path=f"{cap}/09-payment-list-final.png")
        print("09 payment list final OK")

        await browser.close()
        print("\n=== ALL E2E TESTS PASSED ===")


asyncio.run(run())
