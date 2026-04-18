import { LightningElement, track } from 'lwc';

/**
 * Closing Progress Dashboard
 * - 좌측: KPI 카드 + Main Menu
 * - 중앙: 선택된 Main Menu의 Sub Menu
 * - 우측: 선택된 Sub Menu의 Task Grid (3열)
 *
 * 데이터는 일단 클라이언트 하드코딩(데모). 추후 Apex로 이관 가능.
 */
export default class ClosingProgressDashboard extends LightningElement {
    @track selectedMainId = '2';
    @track selectedSubId = '2.2';

    model = buildModel();

    lastUpdatedAt = '2026-04-13 23:26';

    get mainMenu() {
        return this.model.mainMenu.map((m) => ({
            ...m,
            cssClass:
                'menu-item' + (m.id === this.selectedMainId ? ' menu-item--active' : '')
        }));
    }

    get selectedMain() {
        return this.model.mainMenu.find((m) => m.id === this.selectedMainId);
    }

    get subMenu() {
        const main = this.selectedMain;
        if (!main) return [];
        return main.subMenu.map((s) => ({
            ...s,
            cssClass:
                'submenu-item' +
                (s.id === this.selectedSubId ? ' submenu-item--active' : '')
        }));
    }

    get selectedSub() {
        const main = this.selectedMain;
        if (!main) return null;
        return main.subMenu.find((s) => s.id === this.selectedSubId);
    }

    get contentTitle() {
        const s = this.selectedSub;
        return s ? s.label.replace(/^\d+\.\s*/, '') : '';
    }

    get subMenuTitle() {
        const m = this.selectedMain;
        return m ? m.label.replace(/^\d+\.\s*/, '') : '';
    }

    get tasks() {
        const s = this.selectedSub;
        if (!s) return [];
        return s.tasks.map((t) => {
            const status = t.status || 'pending';
            return {
                ...t,
                hasStatus: status === 'completed' || status === 'in-progress',
                statusLabel: statusLabel(status),
                badgeClass: `status-badge status-badge--${status}`,
                numberClass: `task-number task-number--${status}`
            };
        });
    }

    get kpi() {
        let total = 0;
        let completed = 0;
        let inProgress = 0;
        let pending = 0;
        for (const main of this.model.mainMenu) {
            for (const sub of main.subMenu) {
                for (const task of sub.tasks) {
                    total++;
                    if (task.status === 'completed') completed++;
                    else if (task.status === 'in-progress') inProgress++;
                    else pending++;
                }
            }
        }
        const pct = total === 0 ? 0 : (completed / total) * 100;
        return {
            total,
            completed,
            inProgress,
            pending,
            percent: pct.toFixed(2),
            percentWidth: `width: ${pct.toFixed(2)}%;`
        };
    }

    handleMainSelect(event) {
        const id = event.currentTarget.dataset.id;
        if (!id || id === this.selectedMainId) return;
        this.selectedMainId = id;
        const main = this.model.mainMenu.find((m) => m.id === id);
        this.selectedSubId = main && main.subMenu.length ? main.subMenu[0].id : null;
    }

    handleSubSelect(event) {
        const id = event.currentTarget.dataset.id;
        if (!id) return;
        this.selectedSubId = id;
    }
}

function statusLabel(status) {
    switch (status) {
        case 'completed':
            return '완료';
        case 'in-progress':
            return '진행중';
        case 'error':
            return '오류';
        default:
            return '';
    }
}

function genericTasks(prefix, count) {
    const out = [];
    for (let i = 1; i <= count; i++) {
        out.push({
            id: `${prefix}-${i}`,
            number: i,
            label: `${prefix} 태스크 ${i}`,
            status: 'pending'
        });
    }
    return out;
}

function buildProductionTasks() {
    const titles = [
        '[결산 모니터링] 수불현황 - FAB 제공 Trend',
        '생산수불[prod/hist][Sys.LSI]',
        '데이터 이관[prod/hist → TMP]',
        '[CK] 생산수불 체크[Sys.LSI]',
        '데이터 이관[TMP → PROD/HIST]',
        '[ck] 생산수불 체크[Sys.LSI](TMP)',
        'SQ_PROD, SQ_HIST 생성',
        '[ck] 생산수불체크[SEQ][Sys.LSI]',
        'RMA 입고파일 I/F[rma_jpgo]',
        '[OY] 입고파일 IF[stock_gcc]',
        '입고라인 분리(Sale)',
        '[ck] 입고 수불체크',
        '[FABLSS] Hist_Ratio 생성(hist_ratio)',
        '[New] 판매라인 분리(Sale)',
        '매입파일 I/F(imco)',
        '[ck][FABLSS] STOCK/ Sale/ IMCO 체크',
        'SALE vs STOCK 체크',
        '[ck] 생산/입고/판매라인 전량 로스 체크',
        '판매단가(Sale_unit)',
        '멀티칩 판매환산(mchip_sale)',
        '진척율 인터페이스(progress)',
        '[LSI] 단가 생성(전월도 실행)',
        '[LSI] Work Cost 생성',
        '실적 연결 결산용 데이터 Copy',
        '연결수불 생성'
    ];
    return titles.map((label, idx) => {
        const n = idx + 1;
        let status = 'pending';
        if (n <= 4) status = 'completed';
        else if (n === 5) status = 'in-progress';
        return {
            id: `2.2-${n}`,
            number: n,
            label,
            status
        };
    });
}

function buildModel() {
    return {
        mainMenu: [
            {
                id: '1',
                label: '1. 총괄실적',
                subMenu: [
                    {
                        id: '1.1',
                        label: '1. 총괄 집계',
                        tasks: genericTasks('총괄 집계', 15)
                    },
                    {
                        id: '1.2',
                        label: '2. 실적 요약',
                        tasks: genericTasks('실적 요약', 15)
                    }
                ]
            },
            {
                id: '2',
                label: '2. 기준정보',
                subMenu: [
                    {
                        id: '2.1',
                        label: '1. 기준정보/타 시스템 IF',
                        tasks: genericTasks('기준정보/타 시스템 IF', 15)
                    },
                    {
                        id: '2.2',
                        label: '2. 생산/ 입고/ 판매',
                        tasks: buildProductionTasks()
                    },
                    {
                        id: '2.3',
                        label: '3. AGING/ 저가',
                        tasks: genericTasks('AGING/저가', 15)
                    }
                ]
            },
            {
                id: '3',
                label: '3. 생산/ 입고/ 판매',
                subMenu: [
                    {
                        id: '3.1',
                        label: '1. 생산 실적 집계',
                        tasks: genericTasks('생산 실적', 13)
                    },
                    {
                        id: '3.2',
                        label: '2. 판매 실적 집계',
                        tasks: genericTasks('판매 실적', 12)
                    }
                ]
            },
            {
                id: '4',
                label: '4. 재료비/ 가공비/ 재공평가',
                subMenu: [
                    {
                        id: '4.1',
                        label: '1. 재료비 산정',
                        tasks: genericTasks('재료비', 10)
                    },
                    {
                        id: '4.2',
                        label: '2. 가공비/재공평가',
                        tasks: genericTasks('가공비', 10)
                    }
                ]
            },
            {
                id: '5',
                label: '5. O/H 비용/ 총원가/ 송부',
                subMenu: [
                    {
                        id: '5.1',
                        label: '1. O/H 비용 및 송부',
                        tasks: genericTasks('O/H 비용', 10)
                    }
                ]
            }
        ]
    };
}
