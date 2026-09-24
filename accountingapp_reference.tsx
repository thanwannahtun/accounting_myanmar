import React, { useState, useMemo, useRef, useEffect } from 'react';

// Inline SVG Icon components to replace lucide-react and fix forwardRef errors
const IconBase = ({ children, className = '', ...props }) => (
  <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className={className} {...props}>
    {children}
  </svg>
);

const LayoutDashboard = (p) => <IconBase {...p}><rect width="7" height="9" x="3" y="3" rx="1" /><rect width="7" height="5" x="14" y="3" rx="1" /><rect width="7" height="9" x="14" y="12" rx="1" /><rect width="7" height="5" x="3" y="16" rx="1" /></IconBase>;
const BookOpen = (p) => <IconBase {...p}><path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z" /><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z" /></IconBase>;
const ArrowRightLeft = (p) => <IconBase {...p}><path d="m16 3 4 4-4 4" /><path d="M20 7H4" /><path d="m8 21-4-4 4-4" /><path d="M4 17h16" /></IconBase>;
const Plus = (p) => <IconBase {...p}><path d="M5 12h14" /><path d="M12 5v14" /></IconBase>;
const Trash2 = (p) => <IconBase {...p}><path d="M3 6h18" /><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6" /><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2" /><line x1="10" x2="10" y1="11" y2="17" /><line x1="14" x2="14" y1="11" y2="17" /></IconBase>;
const CheckCircle2 = (p) => <IconBase {...p}><circle cx="12" cy="12" r="10" /><path d="m9 12 2 2 4-4" /></IconBase>;
const AlertCircle = (p) => <IconBase {...p}><circle cx="12" cy="12" r="10" /><line x1="12" x2="12" y1="8" y2="12" /><line x1="12" x2="12.01" y1="16" y2="16" /></IconBase>;
const TrendingUp = (p) => <IconBase {...p}><polyline points="22 7 13.5 15.5 8.5 10.5 2 17" /><polyline points="16 7 22 7 22 13" /></IconBase>;
const TrendingDown = (p) => <IconBase {...p}><polyline points="22 17 13.5 8.5 8.5 13.5 2 7" /><polyline points="16 17 22 17 22 11" /></IconBase>;
const DollarSign = (p) => <IconBase {...p}><line x1="12" x2="12" y1="2" y2="22" /><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" /></IconBase>;
const FileText = (p) => <IconBase {...p}><path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z" /><path d="M14 2v4a2 2 0 0 0 2 2h4" /><path d="M10 9H8" /><path d="M16 13H8" /><path d="M16 17H8" /></IconBase>;
const MessageSquare = (p) => <IconBase {...p}><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" /></IconBase>;
const Bot = (p) => <IconBase {...p}><path d="M12 8V4H8" /><rect width="16" height="12" x="4" y="8" rx="2" /><path d="M2 14h2" /><path d="M20 14h2" /><path d="M15 13v2" /><path d="M9 13v2" /></IconBase>;
const Send = (p) => <IconBase {...p}><path d="m22 2-7 20-4-9-9-4Z" /><path d="M22 2 11 13" /></IconBase>;
const Loader2 = (p) => <IconBase {...p}><path d="M21 12a9 9 0 1 1-6.219-8.56" /></IconBase>;
const BarChart3 = (p) => <IconBase {...p}><path d="M3 3v18h18" /><rect width="4" height="7" x="7" y="10" rx="1" /><rect width="4" height="12" x="15" y="5" rx="1" /></IconBase>;
const PieChart = (p) => <IconBase {...p}><path d="M21.21 15.89A10 10 0 1 1 8 2.83" /><path d="M22 12A10 10 0 0 0 12 2v10z" /></IconBase>;
const ListOrdered = (p) => <IconBase {...p}><line x1="10" x2="21" y1="6" y2="6" /><line x1="10" x2="21" y1="12" y2="12" /><line x1="10" x2="21" y1="18" y2="18" /><path d="M4 6h1v4" /><path d="M4 10h2" /><path d="M6 18H4c0-1 2-2 2-3s-1-1.5-2-1" /></IconBase>;

const ACCOUNT_TYPES = ['Asset', 'Liability', 'Equity', 'Revenue', 'Expense'];

const INITIAL_ACCOUNTS = [
  { id: 'a1000', code: '1000', name: 'Cash / Bank', type: 'Asset' },
  { id: 'a1200', code: '1200', name: 'Accounts Receivable (AR)', type: 'Asset' },
  { id: 'a1300', code: '1300', name: 'Inventory', type: 'Asset' },
  { id: 'a1400', code: '1400', name: 'Prepaid Expenses', type: 'Asset' },
  { id: 'a2000', code: '2000', name: 'Accounts Payable (AP)', type: 'Liability' },
  { id: 'a3000', code: '3000', name: 'Owner Equity', type: 'Equity' },
  { id: 'a4000', code: '4000', name: 'Gross Sales Revenue', type: 'Revenue' },
  { id: 'a4100', code: '4100', name: 'Sales Discounts', type: 'Revenue' }, // Contra-revenue
  { id: 'a5000', code: '5000', name: 'Cost of Goods Sold (COGS)', type: 'Expense' },
  { id: 'a5100', code: '5100', name: 'FOC & Damages', type: 'Expense' },
  { id: 'a6001', code: '6001', name: 'Salaries & Commissions', type: 'Expense' },
  { id: 'a6003', code: '6003', name: 'Warehouse & Office Rent', type: 'Expense' },
  { id: 'a8000', code: '8000', name: 'Other Income / FOC Income', type: 'Revenue' },
];

const INITIAL_TRANSACTIONS = [
  {
    id: 't0',
    date: '2026-09-01',
    description: 'Initial Investment (အရင်းအနှီးထည့်ဝင်ခြင်း)',
    lines: [
      { id: 'l0a', accountId: 'a1000', debit: 100000000, credit: 0 },
      { id: 'l0b', accountId: 'a3000', debit: 0, credit: 100000000 },
    ]
  },
  {
    id: 't1_1',
    date: '2026-09-02',
    description: '၁.၁ ငွေအပြည့်ချေပြီး ဝယ်ယူခြင်း (Fully Paid Purchase)',
    lines: [
      { id: 'l1a', accountId: 'a1300', debit: 10000000, credit: 0 },
      { id: 'l1b', accountId: 'a1000', debit: 0, credit: 10000000 },
    ]
  },
  {
    id: 't1_2',
    date: '2026-09-03',
    description: '၁.၂ အကြွေးဖြင့် ဝယ်ယူခြင်း (Purchase on Debt)',
    lines: [
      { id: 'l2a', accountId: 'a1300', debit: 20000000, credit: 0 },
      { id: 'l2b', accountId: 'a2000', debit: 0, credit: 20000000 },
    ]
  },
  {
    id: 't1_3',
    date: '2026-09-04',
    description: '၁.၃ တစ်စိတ်တစ်ပိုင်းသာ ငွေချေပြီး ဝယ်ယူခြင်း (Partial Payment Purchase)',
    lines: [
      { id: 'l3a', accountId: 'a1300', debit: 15000000, credit: 0 },
      { id: 'l3b', accountId: 'a1000', debit: 0, credit: 5000000 },
      { id: 'l3c', accountId: 'a2000', debit: 0, credit: 10000000 },
    ]
  },
  {
    id: 't2_1',
    date: '2026-09-05',
    description: '၂.၁ ငွေအပြည့်ရပြီး ရောင်းချခြင်း (Fully Paid Sale)',
    lines: [
      { id: 'l4a', accountId: 'a1000', debit: 15000000, credit: 0 },
      { id: 'l4b', accountId: 'a4000', debit: 0, credit: 15000000 },
      { id: 'l4c', accountId: 'a5000', debit: 8000000, credit: 0 }, // COGS for the sale
      { id: 'l4d', accountId: 'a1300', debit: 0, credit: 8000000 },
    ]
  },
  {
    id: 't2_2',
    date: '2026-09-06',
    description: '၂.၂ အကြွေးဖြင့် ရောင်းချခြင်း (Sale on Debt)',
    lines: [
      { id: 'l5a', accountId: 'a1200', debit: 20000000, credit: 0 },
      { id: 'l5b', accountId: 'a4000', debit: 0, credit: 20000000 },
      { id: 'l5c', accountId: 'a5000', debit: 11000000, credit: 0 },
      { id: 'l5d', accountId: 'a1300', debit: 0, credit: 11000000 },
    ]
  },
  {
    id: 't2_3',
    date: '2026-09-07',
    description: '၂.၃ တစ်စိတ်တစ်ပိုင်းသာ ငွေရပြီး ရောင်းချခြင်း (Partial Payment Sale)',
    lines: [
      { id: 'l6a', accountId: 'a1000', debit: 10000000, credit: 0 },
      { id: 'l6b', accountId: 'a1200', debit: 15000000, credit: 0 },
      { id: 'l6c', accountId: 'a4000', debit: 0, credit: 25000000 },
      { id: 'l6d', accountId: 'a5000', debit: 14000000, credit: 0 },
      { id: 'l6e', accountId: 'a1300', debit: 0, credit: 14000000 },
    ]
  },
  {
    id: 't3',
    date: '2026-09-08',
    description: '၃။ ဝန်ထမ်းများကို နေ့စားလစာ ပေးချေခြင်း (Paying Daily Salaries)',
    lines: [
      { id: 'l7a', accountId: 'a6001', debit: 2000000, credit: 0 },
      { id: 'l7b', accountId: 'a1000', debit: 0, credit: 2000000 },
    ]
  },
  {
    id: 't4',
    date: '2026-09-09',
    description: '၄။ အရောင်းတွင် လျှော့ဈေးပေးခြင်း (Sales Discount Given)',
    lines: [
      { id: 'l8a', accountId: 'a4100', debit: 500000, credit: 0 },
      { id: 'l8b', accountId: 'a1200', debit: 0, credit: 500000 },
    ]
  },
  {
    id: 't5_1',
    date: '2026-09-10',
    description: '၅.၁ ဝယ်ယူသူအား မိမိဘက်မှ FOC ပေးခြင်း (FOC Given on Sale)',
    lines: [
      { id: 'l9a', accountId: 'a5100', debit: 300000, credit: 0 },
      { id: 'l9b', accountId: 'a1300', debit: 0, credit: 300000 },
    ]
  },
  {
    id: 't5_2',
    date: '2026-09-11',
    description: '၅.၂ Supplier ထံမှ မိမိက FOC ရရှိခြင်း (FOC Received on Purchase)',
    lines: [
      { id: 'l10a', accountId: 'a1300', debit: 400000, credit: 0 },
      { id: 'l10b', accountId: 'a8000', debit: 0, credit: 400000 },
    ]
  },
  {
    id: 't6_1',
    date: '2026-09-12',
    description: '၆.၁ ဖောက်သည်က အကြွေးလာဆပ်ခြင်း (Collecting Payment from AR)',
    lines: [
      { id: 'l11a', accountId: 'a1000', debit: 8000000, credit: 0 },
      { id: 'l11b', accountId: 'a1200', debit: 0, credit: 8000000 },
    ]
  },
  {
    id: 't6_2',
    date: '2026-09-13',
    description: '၆.၂ Supplier ကို အကြွေးသွားဆပ်ခြင်း (Making Payment to AP)',
    lines: [
      { id: 'l12a', accountId: 'a2000', debit: 12000000, credit: 0 },
      { id: 'l12b', accountId: 'a1000', debit: 0, credit: 12000000 },
    ]
  },
  {
    id: 't6_3',
    date: '2026-09-14',
    description: '၆.၃ ရုံးခန်းငှားရမ်းခ ကြိုပေးခြင်း (Prepaid Rent - ၆ လစာ)',
    lines: [
      { id: 'l13a', accountId: 'a1400', debit: 6000000, credit: 0 },
      { id: 'l13b', accountId: 'a1000', debit: 0, credit: 6000000 },
    ]
  },
  {
    id: 't6_3b',
    date: '2026-09-30',
    description: 'ရုံးခန်းငှားရမ်းခ ၁ လစာ စာရင်းပြောင်းခြင်း (Amortize 1 month Rent)',
    lines: [
      { id: 'l14a', accountId: 'a6003', debit: 1000000, credit: 0 },
      { id: 'l14b', accountId: 'a1400', debit: 0, credit: 1000000 },
    ]
  }
];

const formatCurrency = (amount) => {
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'MMK' }).format(amount).replace('MMK', 'Ks');
};

const Card = ({ children, className = '' }) => (
  <div className={`bg-gray-900 border border-gray-800 rounded-xl shadow-sm ${className}`}>
    {children}
  </div>
);

// Helper function to calculate account balances
const calculateBalances = (accounts, transactions) => {
  const balances = {};
  accounts.forEach(acc => { balances[acc.id] = 0; });

  transactions.forEach(t => {
    t.lines.forEach(line => {
      const acc = accounts.find(a => a.id === line.accountId);
      if (!acc) return;

      const amount = Number(line.debit) - Number(line.credit);

      // Normal balance logic
      if (acc.type === 'Asset' || acc.type === 'Expense') {
        balances[acc.id] += amount;
      } else {
        // Liability, Equity, Revenue naturally have credit balances
        balances[acc.id] -= amount;
      }
    });
  });
  return balances;
};

const DashboardView = ({ accounts, transactions }) => {
  const metrics = useMemo(() => {
    let revenue = 0;
    let expense = 0;
    let assets = 0;

    transactions.forEach(t => {
      t.lines.forEach(line => {
        const acc = accounts.find(a => a.id === line.accountId);
        if (!acc) return;

        if (acc.type === 'Revenue') {
          // Treat as credit balance naturally, so debit reduces it
          if (acc.code === '4100') {
            revenue -= (Number(line.debit) - Number(line.credit)); // Contra revenue
          } else {
            revenue += Number(line.credit) - Number(line.debit);
          }
        }
        if (acc.type === 'Expense') expense += Number(line.debit) - Number(line.credit);
        if (acc.type === 'Asset') assets += Number(line.debit) - Number(line.credit);
      });
    });

    const netProfit = revenue - expense;
    return { revenue, expense, netProfit, assets };
  }, [accounts, transactions]);

  return (
    <div className="p-4 md:p-6 space-y-6">
      <header className="mb-6">
        <h1 className="text-2xl font-bold text-white">Dashboard</h1>
        <p className="text-gray-400 text-sm">Monthly Profit & Loss Summary</p>
      </header>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="p-5 flex flex-col justify-between">
          <div className="flex justify-between items-start">
            <div>
              <p className="text-sm font-medium text-gray-400">Total Revenue</p>
              <h3 className="text-xl font-bold text-emerald-400 mt-1">{formatCurrency(metrics.revenue)}</h3>
            </div>
            <div className="p-2 bg-emerald-400/10 rounded-lg">
              <TrendingUp className="w-5 h-5 text-emerald-400" />
            </div>
          </div>
        </Card>

        <Card className="p-5 flex flex-col justify-between">
          <div className="flex justify-between items-start">
            <div>
              <p className="text-sm font-medium text-gray-400">Total Expenses</p>
              <h3 className="text-xl font-bold text-rose-400 mt-1">{formatCurrency(metrics.expense)}</h3>
            </div>
            <div className="p-2 bg-rose-400/10 rounded-lg">
              <TrendingDown className="w-5 h-5 text-rose-400" />
            </div>
          </div>
        </Card>

        <Card className="p-5 flex flex-col justify-between">
          <div className="flex justify-between items-start">
            <div>
              <p className="text-sm font-medium text-gray-400">Net Profit</p>
              <h3 className={`text-xl font-bold mt-1 ${metrics.netProfit >= 0 ? 'text-emerald-400' : 'text-rose-400'}`}>
                {formatCurrency(metrics.netProfit)}
              </h3>
            </div>
            <div className={`p-2 rounded-lg ${metrics.netProfit >= 0 ? 'bg-emerald-400/10' : 'bg-rose-400/10'}`}>
              <DollarSign className={`w-5 h-5 ${metrics.netProfit >= 0 ? 'text-emerald-400' : 'text-rose-400'}`} />
            </div>
          </div>
        </Card>

        <Card className="p-5 flex flex-col justify-between">
          <div className="flex justify-between items-start">
            <div>
              <p className="text-sm font-medium text-gray-400">Total Assets</p>
              <h3 className="text-xl font-bold text-blue-400 mt-1">{formatCurrency(metrics.assets)}</h3>
            </div>
            <div className="p-2 bg-blue-400/10 rounded-lg">
              <BookOpen className="w-5 h-5 text-blue-400" />
            </div>
          </div>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card className="p-5">
          <h3 className="text-lg font-semibold text-white mb-4">Cash Flow Activity (Simplified)</h3>
          <div className="space-y-4">
            {transactions.filter(t => t.lines.some(l => l.accountId === 'a1000')).slice(0, 8).map(t => {
              const cashLine = t.lines.find(l => l.accountId === 'a1000');
              if (!cashLine) return null;
              const isPositive = cashLine.debit > 0;
              const amount = isPositive ? cashLine.debit : cashLine.credit;

              return (
                <div key={t.id} className="flex justify-between items-center p-3 bg-gray-950/50 rounded-lg">
                  <div>
                    <p className="text-sm text-gray-200 font-medium">{t.description}</p>
                    <p className="text-xs text-gray-500">{t.date}</p>
                  </div>
                  <span className={`font-mono font-medium ${isPositive ? 'text-emerald-400' : 'text-rose-400'}`}>
                    {isPositive ? '+' : '-'}{formatCurrency(amount)}
                  </span>
                </div>
              )
            })}
          </div>
        </Card>

        <Card className="p-5 flex items-center justify-center border-dashed border-gray-700">
          <div className="text-center">
            <PieChart className="w-12 h-12 text-gray-600 mx-auto mb-2" />
            <p className="text-gray-400 text-sm">Detailed charts and graphs would go here in a production app.</p>
          </div>
        </Card>
      </div>
    </div>
  );
};

const ReportsView = ({ accounts, transactions }) => {
  const [activeReport, setActiveReport] = useState('income');
  const balances = calculateBalances(accounts, transactions);

  // Group accounts by type
  const groupedAccounts = accounts.reduce((acc, account) => {
    if (!acc[account.type]) acc[account.type] = [];
    acc[account.type].push(account);
    return acc;
  }, {});

  const renderIncomeStatement = () => {
    let totalRevenue = 0;
    let totalCogs = 0;
    let totalOpex = 0;

    const revenues = (groupedAccounts['Revenue'] || []).map(acc => {
      const bal = balances[acc.id];
      // Special handling for contra-revenue (discounts)
      const displayAmount = acc.code === '4100' ? -bal : bal;
      totalRevenue += bal;
      return { ...acc, displayAmount };
    });

    const expenses = (groupedAccounts['Expense'] || []).map(acc => {
      const bal = balances[acc.id];
      if (acc.code.startsWith('5')) { totalCogs += bal; }
      else { totalOpex += bal; }
      return { ...acc, bal };
    });

    const grossProfit = totalRevenue - totalCogs;
    const netProfit = grossProfit - totalOpex;

    return (
      <div className="space-y-6">
        <div className="bg-gray-950/50 p-6 rounded-lg border border-gray-800">
          <h3 className="text-lg font-bold text-white mb-4 border-b border-gray-800 pb-2">Revenue</h3>
          {revenues.map(acc => (
            <div key={acc.id} className="flex justify-between py-2 text-sm">
              <span className="text-gray-400 ml-4">{acc.code} - {acc.name}</span>
              <span className="text-gray-200">{formatCurrency(acc.displayAmount)}</span>
            </div>
          ))}
          <div className="flex justify-between py-2 text-sm font-bold border-t border-gray-800 mt-2">
            <span className="text-gray-200">Total Net Revenue</span>
            <span className="text-emerald-400">{formatCurrency(totalRevenue)}</span>
          </div>

          <h3 className="text-lg font-bold text-white mb-4 mt-6 border-b border-gray-800 pb-2">Cost of Goods Sold (COGS)</h3>
          {expenses.filter(a => a.code.startsWith('5')).map(acc => (
            <div key={acc.id} className="flex justify-between py-2 text-sm">
              <span className="text-gray-400 ml-4">{acc.code} - {acc.name}</span>
              <span className="text-rose-400">-{formatCurrency(acc.bal)}</span>
            </div>
          ))}
          <div className="flex justify-between py-3 text-sm font-bold bg-gray-900/50 px-4 -mx-4 mt-4">
            <span className="text-gray-200">Gross Profit</span>
            <span className="text-blue-400">{formatCurrency(grossProfit)}</span>
          </div>

          <h3 className="text-lg font-bold text-white mb-4 mt-6 border-b border-gray-800 pb-2">Operating Expenses</h3>
          {expenses.filter(a => !a.code.startsWith('5')).map(acc => (
            <div key={acc.id} className="flex justify-between py-2 text-sm">
              <span className="text-gray-400 ml-4">{acc.code} - {acc.name}</span>
              <span className="text-rose-400">-{formatCurrency(acc.bal)}</span>
            </div>
          ))}
          <div className="flex justify-between py-2 text-sm font-bold border-t border-gray-800 mt-2">
            <span className="text-gray-200">Total Operating Expenses</span>
            <span className="text-rose-400">-{formatCurrency(totalOpex)}</span>
          </div>
        </div>

        <div className={`p-4 rounded-lg flex justify-between items-center border ${netProfit >= 0 ? 'bg-emerald-900/20 border-emerald-800' : 'bg-rose-900/20 border-rose-800'}`}>
          <span className="text-lg font-bold text-white">Net Profit / Loss</span>
          <span className={`text-2xl font-bold ${netProfit >= 0 ? 'text-emerald-400' : 'text-rose-400'}`}>{formatCurrency(netProfit)}</span>
        </div>
      </div>
    );
  };

  const renderBalanceSheet = () => {
    let totalAssets = 0;
    let totalLiabilities = 0;
    let totalEquity = 0;

    const assets = (groupedAccounts['Asset'] || []).map(acc => {
      totalAssets += balances[acc.id];
      return acc;
    });
    const liabilities = (groupedAccounts['Liability'] || []).map(acc => {
      totalLiabilities += balances[acc.id];
      return acc;
    });
    const equities = (groupedAccounts['Equity'] || []).map(acc => {
      totalEquity += balances[acc.id];
      return acc;
    });

    // Calculate current period net income to add to equity
    let netIncome = 0;
    accounts.forEach(acc => {
      if (acc.type === 'Revenue') netIncome += balances[acc.id];
      if (acc.type === 'Expense') netIncome -= balances[acc.id];
    });

    const totalLiabilitiesAndEquity = totalLiabilities + totalEquity + netIncome;
    const isBalanced = totalAssets === totalLiabilitiesAndEquity;

    return (
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Assets Column */}
        <div className="bg-gray-950/50 p-6 rounded-lg border border-gray-800 flex flex-col h-full">
          <h3 className="text-xl font-bold text-blue-400 mb-6 border-b border-gray-800 pb-2">Assets</h3>
          <div className="flex-1 space-y-2">
            {assets.map(acc => (
              <div key={acc.id} className="flex justify-between py-2 text-sm">
                <span className="text-gray-400">{acc.code} - {acc.name}</span>
                <span className="text-gray-200">{formatCurrency(balances[acc.id])}</span>
              </div>
            ))}
          </div>
          <div className="flex justify-between py-3 text-base font-bold border-t-2 border-gray-700 mt-6">
            <span className="text-white">Total Assets</span>
            <span className="text-blue-400">{formatCurrency(totalAssets)}</span>
          </div>
        </div>

        {/* Liabilities & Equity Column */}
        <div className="flex flex-col gap-6 h-full">
          <div className="bg-gray-950/50 p-6 rounded-lg border border-gray-800">
            <h3 className="text-xl font-bold text-rose-400 mb-6 border-b border-gray-800 pb-2">Liabilities</h3>
            <div className="space-y-2">
              {liabilities.map(acc => (
                <div key={acc.id} className="flex justify-between py-2 text-sm">
                  <span className="text-gray-400">{acc.code} - {acc.name}</span>
                  <span className="text-gray-200">{formatCurrency(balances[acc.id])}</span>
                </div>
              ))}
            </div>
            <div className="flex justify-between py-3 text-sm font-bold border-t border-gray-800 mt-4">
              <span className="text-gray-300">Total Liabilities</span>
              <span className="text-rose-400">{formatCurrency(totalLiabilities)}</span>
            </div>
          </div>

          <div className="bg-gray-950/50 p-6 rounded-lg border border-gray-800 flex-1 flex flex-col">
            <h3 className="text-xl font-bold text-purple-400 mb-6 border-b border-gray-800 pb-2">Equity</h3>
            <div className="space-y-2 flex-1">
              {equities.map(acc => (
                <div key={acc.id} className="flex justify-between py-2 text-sm">
                  <span className="text-gray-400">{acc.code} - {acc.name}</span>
                  <span className="text-gray-200">{formatCurrency(balances[acc.id])}</span>
                </div>
              ))}
              <div className="flex justify-between py-2 text-sm">
                <span className="text-gray-400 text-xs italic">Current Period Net Income</span>
                <span className="text-gray-200">{formatCurrency(netIncome)}</span>
              </div>
            </div>

            <div className="flex justify-between py-3 text-base font-bold border-t-2 border-gray-700 mt-6">
              <span className="text-white">Total L. & Equity</span>
              <span className="text-purple-400">{formatCurrency(totalLiabilitiesAndEquity)}</span>
            </div>
          </div>
        </div>

        {/* Balance Check Indicator */}
        <div className={`col-span-1 lg:col-span-2 p-3 rounded-lg flex items-center justify-center gap-2 ${isBalanced ? 'bg-emerald-900/20 text-emerald-400' : 'bg-rose-900/20 text-rose-400'}`}>
          {isBalanced ? <CheckCircle2 className="w-5 h-5" /> : <AlertCircle className="w-5 h-5" />}
          <span className="font-medium">
            {isBalanced ? "Balance Sheet is Balanced" : "Balance Sheet is OUT OF BALANCE"}
          </span>
        </div>
      </div>
    );
  };

  return (
    <div className="p-4 md:p-6 space-y-6">
      <header className="mb-6">
        <h1 className="text-2xl font-bold text-white">Financial Reports</h1>
        <p className="text-gray-400 text-sm">Generate and view essential statements</p>
      </header>

      <div className="flex gap-2 p-1 bg-gray-900 rounded-lg w-fit border border-gray-800 mb-6">
        <button
          onClick={() => setActiveReport('income')}
          className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${activeReport === 'income' ? 'bg-blue-600 text-white' : 'text-gray-400 hover:text-white'}`}
        >
          Income Statement (P&L)
        </button>
        <button
          onClick={() => setActiveReport('balance')}
          className={`px-4 py-2 rounded-md text-sm font-medium transition-colors ${activeReport === 'balance' ? 'bg-blue-600 text-white' : 'text-gray-400 hover:text-white'}`}
        >
          Balance Sheet
        </button>
      </div>

      <Card className="p-4 md:p-6 shadow-xl">
        {activeReport === 'income' && renderIncomeStatement()}
        {activeReport === 'balance' && renderBalanceSheet()}
      </Card>
    </div>
  )
}

const GeneralLedgerView = ({ accounts, transactions }) => {
  const [selectedAccountId, setSelectedAccountId] = useState(accounts[0]?.id || '');

  const accountTransactions = useMemo(() => {
    if (!selectedAccountId) return [];

    let runningBalance = 0;
    const selectedAcc = accounts.find(a => a.id === selectedAccountId);
    if (!selectedAcc) return [];

    const lines = [];

    // Sort transactions by date
    const sortedTx = [...transactions].sort((a, b) => new Date(a.date) - new Date(b.date));

    sortedTx.forEach(t => {
      const line = t.lines.find(l => l.accountId === selectedAccountId);
      if (line) {
        const debit = Number(line.debit);
        const credit = Number(line.credit);

        if (selectedAcc.type === 'Asset' || selectedAcc.type === 'Expense') {
          runningBalance += (debit - credit);
        } else {
          runningBalance += (credit - debit);
        }

        lines.push({
          date: t.date,
          description: t.description,
          txId: t.id,
          debit,
          credit,
          balance: runningBalance
        });
      }
    });
    return lines;
  }, [selectedAccountId, transactions, accounts]);

  const selectedAccount = accounts.find(a => a.id === selectedAccountId);

  return (
    <div className="p-4 md:p-6 space-y-6">
      <header className="mb-6 flex flex-col md:flex-row md:items-end justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-white">General Ledger</h1>
          <p className="text-gray-400 text-sm">Detailed transaction history by account</p>
        </div>

        <div className="w-full md:w-72">
          <label className="block text-xs font-medium text-gray-400 mb-1">Select Account</label>
          <select
            value={selectedAccountId}
            onChange={e => setSelectedAccountId(e.target.value)}
            className="w-full bg-gray-900 border border-gray-700 rounded-lg p-2.5 text-sm text-white focus:border-blue-500 outline-none"
          >
            {accounts.sort((a, b) => a.code.localeCompare(b.code)).map(acc => (
              <option key={acc.id} value={acc.id}>{acc.code} - {acc.name}</option>
            ))}
          </select>
        </div>
      </header>

      <Card className="overflow-hidden">
        <div className="p-4 border-b border-gray-800 bg-gray-900/50 flex justify-between items-center">
          <div>
            <h3 className="text-lg font-bold text-white">{selectedAccount?.name}</h3>
            <p className="text-sm text-gray-400">Account Type: <span className="text-gray-200">{selectedAccount?.type}</span></p>
          </div>
          <div className="text-right">
            <p className="text-xs text-gray-400">Ending Balance</p>
            <p className="text-xl font-mono font-bold text-blue-400">
              {formatCurrency(accountTransactions.length > 0 ? accountTransactions[accountTransactions.length - 1].balance : 0)}
            </p>
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-gray-950/50 text-gray-400">
              <tr>
                <th className="px-5 py-3 font-medium">Date</th>
                <th className="px-5 py-3 font-medium">Description</th>
                <th className="px-5 py-3 font-medium text-right">Debit</th>
                <th className="px-5 py-3 font-medium text-right">Credit</th>
                <th className="px-5 py-3 font-medium text-right bg-gray-900/30">Balance</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-800">
              {accountTransactions.length === 0 ? (
                <tr>
                  <td colSpan="5" className="px-5 py-8 text-center text-gray-500">No transactions found for this account.</td>
                </tr>
              ) : (
                accountTransactions.map((line, i) => (
                  <tr key={i} className="hover:bg-gray-800/50 transition-colors">
                    <td className="px-5 py-3 text-gray-400 whitespace-nowrap">{line.date}</td>
                    <td className="px-5 py-3 text-gray-200">{line.description}</td>
                    <td className="px-5 py-3 text-right text-emerald-400 font-mono">{line.debit > 0 ? line.debit.toLocaleString() : '-'}</td>
                    <td className="px-5 py-3 text-right text-rose-400 font-mono">{line.credit > 0 ? line.credit.toLocaleString() : '-'}</td>
                    <td className="px-5 py-3 text-right text-blue-400 font-mono bg-gray-900/10 font-medium">
                      {line.balance.toLocaleString()}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  )
}

const AccountsView = ({ accounts, onAddAccount }) => {
  const [isAdding, setIsAdding] = useState(false);
  const [newAcc, setNewAcc] = useState({ code: '', name: '', type: 'Revenue' });

  const handleSave = () => {
    if (newAcc.code && newAcc.name) {
      onAddAccount({ ...newAcc, id: Date.now().toString() });
      setIsAdding(false);
      setNewAcc({ code: '', name: '', type: 'Revenue' });
    }
  };

  return (
    <div className="p-4 md:p-6 space-y-6">
      <header className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
        <div>
          <h1 className="text-2xl font-bold text-white">Chart of Accounts</h1>
          <p className="text-gray-400 text-sm">Manage your ledger accounts dynamically</p>
        </div>
        <button
          onClick={() => setIsAdding(true)}
          className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-medium transition-colors w-full sm:w-auto justify-center"
        >
          <Plus className="w-4 h-4" /> Add Account
        </button>
      </header>

      {isAdding && (
        <Card className="p-5 border-blue-500/30 bg-blue-900/10 mb-6">
          <h3 className="text-lg font-semibold text-white mb-4">New Account</h3>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-4">
            <div>
              <label className="block text-xs font-medium text-gray-400 mb-1">GL Code</label>
              <input
                type="text"
                value={newAcc.code}
                onChange={e => setNewAcc({ ...newAcc, code: e.target.value })}
                placeholder="e.g. 6002"
                className="w-full bg-gray-950 border border-gray-700 rounded-lg p-2.5 text-white focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-400 mb-1">Account Name</label>
              <input
                type="text"
                value={newAcc.name}
                onChange={e => setNewAcc({ ...newAcc, name: e.target.value })}
                placeholder="e.g. Fuel & Vehicle Maintenance"
                className="w-full bg-gray-950 border border-gray-700 rounded-lg p-2.5 text-white focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-400 mb-1">Account Type</label>
              <select
                value={newAcc.type}
                onChange={e => setNewAcc({ ...newAcc, type: e.target.value })}
                className="w-full bg-gray-950 border border-gray-700 rounded-lg p-2.5 text-white focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none"
              >
                {ACCOUNT_TYPES.map(type => <option key={type} value={type}>{type}</option>)}
              </select>
            </div>
          </div>
          <div className="flex gap-3 justify-end">
            <button onClick={() => setIsAdding(false)} className="px-4 py-2 text-gray-400 hover:text-white transition-colors">Cancel</button>
            <button onClick={handleSave} className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors">Save Account</button>
          </div>
        </Card>
      )}

      <Card className="overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-gray-950/50 text-gray-400">
              <tr>
                <th className="px-5 py-3 font-medium">GL Code</th>
                <th className="px-5 py-3 font-medium">Account Name</th>
                <th className="px-5 py-3 font-medium">Type</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-800">
              {accounts.sort((a, b) => a.code.localeCompare(b.code)).map((acc) => (
                <tr key={acc.id} className="hover:bg-gray-800/50 transition-colors">
                  <td className="px-5 py-4 text-gray-400">{acc.code}</td>
                  <td className="px-5 py-4 text-gray-200 font-medium">{acc.name}</td>
                  <td className="px-5 py-4">
                    <span className={`px-2 py-1 rounded-md text-xs font-medium border ${acc.type === 'Revenue' ? 'bg-emerald-900/30 text-emerald-400 border-emerald-800/50' :
                        acc.type === 'Expense' ? 'bg-rose-900/30 text-rose-400 border-rose-800/50' :
                          acc.type === 'Asset' ? 'bg-blue-900/30 text-blue-400 border-blue-800/50' :
                            'bg-gray-800 text-gray-300 border-gray-700'
                      }`}>
                      {acc.type}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>
    </div>
  );
};

const TransactionsView = ({ accounts, transactions, onAddTransaction }) => {
  const [isAdding, setIsAdding] = useState(false);
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);
  const [description, setDescription] = useState('');
  const [lines, setLines] = useState([
    { id: '1', accountId: '', debit: '', credit: '' },
    { id: '2', accountId: '', debit: '', credit: '' },
  ]);

  const totalDebit = lines.reduce((sum, line) => sum + Number(line.debit || 0), 0);
  const totalCredit = lines.reduce((sum, line) => sum + Number(line.credit || 0), 0);
  const isBalanced = totalDebit === totalCredit && totalDebit > 0;

  const handleAddLine = () => {
    setLines([...lines, { id: Date.now().toString(), accountId: '', debit: '', credit: '' }]);
  };

  const handleRemoveLine = (id) => {
    if (lines.length > 2) {
      setLines(lines.filter(l => l.id !== id));
    }
  };

  const handleLineChange = (id, field, value) => {
    setLines(lines.map(l => l.id === id ? { ...l, [field]: value } : l));
  };

  const handleSave = () => {
    if (isBalanced && description) {
      onAddTransaction({
        id: Date.now().toString(),
        date,
        description,
        lines: lines.map(l => ({ ...l, debit: Number(l.debit || 0), credit: Number(l.credit || 0) })).filter(l => l.accountId !== '')
      });
      setIsAdding(false);
      setDescription('');
      setLines([
        { id: '1', accountId: '', debit: '', credit: '' },
        { id: '2', accountId: '', debit: '', credit: '' },
      ]);
    }
  };

  return (
    <div className="p-4 md:p-6 space-y-6">
      <header className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
        <div>
          <h1 className="text-2xl font-bold text-white">Journal Entries</h1>
          <p className="text-gray-400 text-sm">Record and manage financial transactions</p>
        </div>
        <button
          onClick={() => setIsAdding(true)}
          className="flex items-center gap-2 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-medium transition-colors w-full sm:w-auto justify-center"
        >
          <Plus className="w-4 h-4" /> New Entry
        </button>
      </header>

      {isAdding && (
        <Card className="p-4 md:p-6 border-blue-500/30 bg-blue-900/10 mb-6 shadow-xl">
          <div className="flex justify-between items-center mb-6 border-b border-gray-800 pb-4">
            <h3 className="text-lg font-semibold text-white">Create Journal Entry</h3>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
            <div>
              <label className="block text-xs font-medium text-gray-400 mb-1">Date</label>
              <input
                type="date"
                value={date}
                onChange={e => setDate(e.target.value)}
                className="w-full bg-gray-950 border border-gray-700 rounded-lg p-2.5 text-white focus:border-blue-500 outline-none color-scheme-dark"
                style={{ colorScheme: 'dark' }}
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-400 mb-1">Description / Memo</label>
              <input
                type="text"
                value={description}
                onChange={e => setDescription(e.target.value)}
                placeholder="e.g. Paid monthly rent"
                className="w-full bg-gray-950 border border-gray-700 rounded-lg p-2.5 text-white focus:border-blue-500 outline-none"
              />
            </div>
          </div>

          <div className="space-y-3 mb-6">
            <div className="hidden md:grid grid-cols-12 gap-2 px-2 text-xs font-medium text-gray-400">
              <div className="col-span-6">Account</div>
              <div className="col-span-2 text-right">Debit</div>
              <div className="col-span-2 text-right">Credit</div>
              <div className="col-span-2"></div>
            </div>

            {lines.map((line, index) => (
              <div key={line.id} className="grid grid-cols-1 md:grid-cols-12 gap-3 items-center bg-gray-950/50 p-3 md:p-2 rounded-lg md:bg-transparent">
                <div className="col-span-1 md:col-span-6">
                  <label className="block md:hidden text-xs font-medium text-gray-400 mb-1">Account</label>
                  <select
                    value={line.accountId}
                    onChange={e => handleLineChange(line.id, 'accountId', e.target.value)}
                    className="w-full bg-gray-900 border border-gray-700 rounded-lg p-2.5 text-sm text-white focus:border-blue-500 outline-none"
                  >
                    <option value="">Select Account...</option>
                    {accounts.map(acc => (
                      <option key={acc.id} value={acc.id}>{acc.code} - {acc.name} ({acc.type})</option>
                    ))}
                  </select>
                </div>
                <div className="col-span-1 md:col-span-2">
                  <label className="block md:hidden text-xs font-medium text-gray-400 mb-1">Debit</label>
                  <input
                    type="number"
                    min="0"
                    placeholder="0.00"
                    value={line.debit}
                    onChange={e => handleLineChange(line.id, 'debit', e.target.value)}
                    disabled={Number(line.credit) > 0}
                    className="w-full bg-gray-900 border border-gray-700 rounded-lg p-2.5 text-sm text-right text-emerald-400 focus:border-blue-500 outline-none disabled:opacity-30"
                  />
                </div>
                <div className="col-span-1 md:col-span-2">
                  <label className="block md:hidden text-xs font-medium text-gray-400 mb-1">Credit</label>
                  <input
                    type="number"
                    min="0"
                    placeholder="0.00"
                    value={line.credit}
                    onChange={e => handleLineChange(line.id, 'credit', e.target.value)}
                    disabled={Number(line.debit) > 0}
                    className="w-full bg-gray-900 border border-gray-700 rounded-lg p-2.5 text-sm text-right text-rose-400 focus:border-blue-500 outline-none disabled:opacity-30"
                  />
                </div>
                <div className="col-span-1 md:col-span-2 flex justify-end md:justify-center">
                  <button
                    onClick={() => handleRemoveLine(line.id)}
                    disabled={lines.length <= 2}
                    className="p-2 text-gray-500 hover:text-rose-400 disabled:opacity-30 transition-colors rounded-lg hover:bg-gray-800"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>

          <div className="flex flex-col md:flex-row justify-between items-center gap-4 pt-4 border-t border-gray-800">
            <button onClick={handleAddLine} className="text-blue-400 hover:text-blue-300 text-sm font-medium w-full md:w-auto text-left">
              + Add Line Item
            </button>

            <div className="flex flex-col md:flex-row items-end md:items-center gap-4 w-full md:w-auto">
              <div className="flex gap-4 text-sm w-full md:w-auto justify-between md:justify-end bg-gray-950 p-3 rounded-lg border border-gray-800">
                <div className="text-right">
                  <span className="text-gray-400 block text-xs">Total Debit</span>
                  <span className={`font-mono font-medium ${totalDebit > 0 ? 'text-emerald-400' : 'text-gray-500'}`}>{totalDebit.toLocaleString()}</span>
                </div>
                <div className="text-right">
                  <span className="text-gray-400 block text-xs">Total Credit</span>
                  <span className={`font-mono font-medium ${totalCredit > 0 ? 'text-rose-400' : 'text-gray-500'}`}>{totalCredit.toLocaleString()}</span>
                </div>
              </div>

              <div className="flex gap-3 w-full md:w-auto">
                <button onClick={() => setIsAdding(false)} className="px-4 py-2.5 flex-1 md:flex-none text-gray-400 hover:text-white bg-gray-800/50 hover:bg-gray-800 rounded-lg transition-colors text-sm font-medium">Cancel</button>
                <button
                  onClick={handleSave}
                  disabled={!isBalanced || !description}
                  className="px-4 py-2.5 flex-1 md:flex-none bg-blue-600 hover:bg-blue-700 disabled:bg-gray-700 disabled:text-gray-500 text-white rounded-lg transition-colors flex items-center justify-center gap-2 text-sm font-medium"
                >
                  {isBalanced && description ? <CheckCircle2 className="w-4 h-4" /> : <AlertCircle className="w-4 h-4" />}
                  Save Entry
                </button>
              </div>
            </div>
          </div>
        </Card>
      )}

      <div className="space-y-4">
        {transactions.map(t => (
          <Card key={t.id} className="overflow-hidden">
            <div className="p-4 border-b border-gray-800 bg-gray-900/50 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
              <div>
                <span className="text-xs font-medium text-gray-400 block mb-1">{t.date}</span>
                <h4 className="text-sm font-semibold text-white">{t.description}</h4>
              </div>
              <span className="text-xs text-gray-500 font-mono">#{t.id}</span>
            </div>
            <div className="p-0">
              <table className="w-full text-left text-sm">
                <thead className="hidden md:table-header-group bg-gray-950/30 text-gray-500 text-xs">
                  <tr>
                    <th className="px-4 py-2 font-medium">Account</th>
                    <th className="px-4 py-2 font-medium text-right">Debit</th>
                    <th className="px-4 py-2 font-medium text-right">Credit</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-800/50">
                  {t.lines.map((l, i) => {
                    const acc = accounts.find(a => a.id === l.accountId);
                    if (!acc) return null;
                    return (
                      <tr key={i} className="flex flex-col md:table-row p-3 md:p-0">
                        <td className="px-4 py-1 md:py-3 text-gray-300">
                          <span className="md:hidden text-xs text-gray-500 mr-2">Account:</span>
                          {acc.code} - {acc.name}
                        </td>
                        <td className="px-4 py-1 md:py-3 text-right">
                          <span className="md:hidden text-xs text-gray-500 mr-2 float-left">Debit:</span>
                          <span className="text-emerald-400 font-mono">{l.debit > 0 ? l.debit.toLocaleString() : '-'}</span>
                        </td>
                        <td className="px-4 py-1 md:py-3 text-right">
                          <span className="md:hidden text-xs text-gray-500 mr-2 float-left">Credit:</span>
                          <span className="text-rose-400 font-mono">{l.credit > 0 ? l.credit.toLocaleString() : '-'}</span>
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
};

const AIAssistantView = () => {
  const [input, setInput] = useState('');
  const [messages, setMessages] = useState([
    { role: 'model', text: 'မင်္ဂလာပါ။ ကျွန်တော်ကတော့ AI စာရင်းကိုင် အကူအညီပေးရေး လက်ထောက် (AI Accounting Assistant) ဖြစ်ပါတယ်။ စာရင်းရေးသွင်းပုံတွေ၊ Debit/Credit သဘောတရားတွေနဲ့ ပတ်သက်ပြီး သိလိုသမျှကို မေးမြန်းနိုင်ပါတယ်။' }
  ]);
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages, isLoading]);

  const handleSend = async () => {
    if (!input.trim() || isLoading) return;

    const userMsg = input.trim();
    setInput('');
    const newMessages = [...messages, { role: 'user', text: userMsg }];
    setMessages(newMessages);
    setIsLoading(true);

    try {
      const apiKey = ""; // API key is handled automatically by the environment
      const apiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent?key=${apiKey}`;

      const payload = {
        contents: newMessages.map(m => ({
          role: m.role,
          parts: [{ text: m.text }]
        })),
        systemInstruction: {
          parts: [{
            text: "Act as an expert accountant and financial advisor. Provide clear, concise answers about accounting principles, journal entries (debits/credits), and financial management. Explain concepts clearly. You can answer in Burmese or English depending on the user's language. Keep answers practical and directly applicable to business workflows. Format responses with markdown for readability."
          }]
        }
      };

      const response = await fetch(apiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });

      const data = await response.json();

      if (data.candidates && data.candidates[0]?.content?.parts?.[0]?.text) {
        const aiText = data.candidates[0].content.parts[0].text;
        setMessages(prev => [...prev, { role: 'model', text: aiText }]);
      } else {
        setMessages(prev => [...prev, { role: 'model', text: 'တောင်းပန်ပါတယ်။ အခုချိန်မှာ ဖြေကြားပေးဖို့ အခက်အခဲရှိနေပါတယ်။ နောက်မှ ထပ်မေးကြည့်ပါ။ (Error processing request)' }]);
      }
    } catch (error) {
      console.error("AI Assistant Error:", error);
      setMessages(prev => [...prev, { role: 'model', text: 'အင်တာနက် ချိတ်ဆက်မှု အခက်အခဲရှိနေပါတယ်။ ကျေးဇူးပြု၍ ခဏနေမှ ပြန်လည် ကြိုးစားကြည့်ပါ။ (Network Error)' }]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  return (
    <div className="p-4 md:p-6 h-[calc(100vh-64px)] md:h-[calc(100vh-0px)] flex flex-col max-w-4xl mx-auto">
      <header className="mb-6 shrink-0">
        <h1 className="text-2xl font-bold text-white flex items-center gap-3">
          <Bot className="text-blue-400 w-8 h-8" />
          AI Accounting Assistant
        </h1>
        <p className="text-gray-400 text-sm mt-1">Ask questions about journal entries, accounts, or financial reporting</p>
      </header>

      <Card className="flex-1 flex flex-col overflow-hidden border-blue-900/30">
        <div className="flex-1 overflow-y-auto p-4 space-y-4">
          {messages.map((msg, index) => (
            <div key={index} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
              <div className={`max-w-[85%] md:max-w-[75%] rounded-2xl p-4 whitespace-pre-wrap text-sm leading-relaxed ${msg.role === 'user'
                  ? 'bg-blue-600 text-white rounded-tr-sm'
                  : 'bg-gray-800 text-gray-200 border border-gray-700 rounded-tl-sm'
                }`}>
                {msg.text}
              </div>
            </div>
          ))}
          {isLoading && (
            <div className="flex justify-start">
              <div className="bg-gray-800 border border-gray-700 rounded-2xl rounded-tl-sm p-4 flex items-center gap-3 text-gray-400">
                <Loader2 className="w-5 h-5 animate-spin text-blue-400" />
                <span className="text-sm">Thinking...</span>
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        <div className="p-4 bg-gray-900/80 border-t border-gray-800 shrink-0">
          <div className="relative flex items-center">
            <textarea
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="Ask about debit/credit, how to record a sale, etc..."
              className="w-full bg-gray-950 border border-gray-700 rounded-xl py-3 pl-4 pr-12 text-sm text-white focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none resize-none h-[52px] overflow-hidden leading-normal"
              rows={1}
            />
            <button
              onClick={handleSend}
              disabled={!input.trim() || isLoading}
              className="absolute right-2 p-2 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-800 disabled:text-gray-500 text-white rounded-lg transition-colors flex items-center justify-center"
            >
              <Send className="w-4 h-4" />
            </button>
          </div>
          <p className="text-xs text-gray-500 text-center mt-3">
            AI can make mistakes. Always verify important accounting decisions.
          </p>
        </div>
      </Card>
    </div>
  );
};

export default function App() {
  const [currentView, setCurrentView] = useState('dashboard');
  const [accounts, setAccounts] = useState(INITIAL_ACCOUNTS);
  const [transactions, setTransactions] = useState(INITIAL_TRANSACTIONS);

  const NavItem = ({ id, label, icon: Icon, hideOnMobile }) => (
    <button
      onClick={() => setCurrentView(id)}
      className={`flex flex-col md:flex-row items-center gap-1 md:gap-3 p-2 md:px-4 md:py-3 rounded-lg md:w-full transition-all ${hideOnMobile ? 'hidden md:flex' : 'flex'
        } ${currentView === id
          ? 'text-blue-400 md:bg-blue-900/20'
          : 'text-gray-400 hover:text-gray-200 hover:bg-gray-800'
        }`}
    >
      <Icon className={`w-5 h-5 md:w-5 md:h-5 ${currentView === id ? 'text-blue-400' : 'text-gray-400'}`} />
      <span className="text-[10px] md:text-sm font-medium">{label}</span>
    </button>
  );

  return (
    <div className="flex flex-col md:flex-row h-screen bg-gray-950 text-gray-100 font-sans overflow-hidden">

      {/* Tablet/Desktop Sidebar */}
      <aside className="hidden md:flex flex-col w-64 bg-gray-900 border-r border-gray-800 shrink-0 z-20">
        <div className="p-6 border-b border-gray-800">
          <div className="flex items-center gap-2 text-blue-500">
            <div className="p-1.5 bg-blue-500/20 rounded-lg">
              <FileText className="w-6 h-6" />
            </div>
            <span className="text-xl font-bold text-white tracking-tight">LedgerPro</span>
          </div>
        </div>
        <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
          <div className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2 mt-4 px-2">Overview</div>
          <NavItem id="dashboard" label="Dashboard" icon={LayoutDashboard} />

          <div className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2 mt-6 px-2">Data Entry</div>
          <NavItem id="transactions" label="Journal Entries" icon={ArrowRightLeft} />
          <NavItem id="accounts" label="Chart of Accounts" icon={BookOpen} />

          <div className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2 mt-6 px-2">Reporting</div>
          <NavItem id="gl" label="General Ledger" icon={ListOrdered} />
          <NavItem id="reports" label="Financial Statements" icon={BarChart3} />

          <div className="pt-4 mt-6 border-t border-gray-800">
            <NavItem id="ai-assistant" label="AI Assistant" icon={MessageSquare} />
          </div>
        </nav>
        <div className="p-4 border-t border-gray-800">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-full bg-gray-800 flex items-center justify-center text-xs font-bold text-gray-400">
              AD
            </div>
            <div className="flex flex-col">
              <span className="text-sm font-medium text-gray-200">Admin User</span>
              <span className="text-xs text-gray-500">Workspace Owner</span>
            </div>
          </div>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="flex-1 overflow-y-auto pb-20 md:pb-0 scroll-smooth">
        {/* Mobile Header */}
        <div className="md:hidden flex items-center justify-between p-4 bg-gray-900 border-b border-gray-800 sticky top-0 z-10">
          <div className="flex items-center gap-2 text-blue-500">
            <FileText className="w-5 h-5" />
            <span className="text-lg font-bold text-white">LedgerPro</span>
          </div>
        </div>

        {/* Dynamic Views */}
        <div className="max-w-7xl mx-auto h-full">
          {currentView === 'dashboard' && <DashboardView accounts={accounts} transactions={transactions} />}
          {currentView === 'accounts' && <AccountsView accounts={accounts} onAddAccount={(acc) => setAccounts([...accounts, acc])} />}
          {currentView === 'transactions' && <TransactionsView accounts={accounts} transactions={transactions} onAddTransaction={(t) => setTransactions([...transactions, t])} />}
          {currentView === 'gl' && <GeneralLedgerView accounts={accounts} transactions={transactions} />}
          {currentView === 'reports' && <ReportsView accounts={accounts} transactions={transactions} />}
          {currentView === 'ai-assistant' && <AIAssistantView />}
        </div>
      </main>

      {/* Mobile Bottom Tab Bar */}
      <nav className="md:hidden fixed bottom-0 left-0 right-0 bg-gray-900/95 backdrop-blur border-t border-gray-800 flex justify-around items-center px-1 py-1 z-20 pb-safe">
        <NavItem id="dashboard" label="Home" icon={LayoutDashboard} />
        <NavItem id="transactions" label="Entries" icon={ArrowRightLeft} />
        <NavItem id="gl" label="Ledger" icon={ListOrdered} />
        <NavItem id="reports" label="Reports" icon={BarChart3} />
        <NavItem id="ai-assistant" label="AI" icon={MessageSquare} hideOnMobile />
      </nav>
    </div>
  );
}