requires 'perl', '5.008005';

requires 'DBIx::Class', '0.082820';

on test => sub {
    requires 'Test::More', '0.96';
    requires 'Test::Fatal', '0.014';
    requires 'DBD::SQLite', '1.46';
    requires 'DateTime', '1.18';
};
