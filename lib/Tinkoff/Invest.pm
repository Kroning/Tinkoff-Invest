package Tinkoff::Invest;

use strict;
use warnings;
use vars qw(@ISA $VERSION);

$VERSION = "0.01";

use Carp ();
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use JSON;
use Data::Dumper;
use URI::Escape;

my $sanbox_url = 'https://api-invest.tinkoff.ru/openapi/sandbox';
my $invest_url = 'https://api-invest.tinkoff.ru/openapi';

sub new {
	my($class, %cnf) = @_;

	my $token = delete $cnf{token};
	Carp::croak("You must provide token new->(token=>'your_token')") if !$token;
	my $debug = delete $cnf{debug};
	my $timeout = delete $cnf{timeout};

	my $self = bless {
		token  => $token,
		api_url => $invest_url,
		debug => $debug,
		timeout => $timeout,
		accountId => '',
		errstr => '',
		errstatus => '',
		returned_json => ''
	}, $class;

	return $self;
}

sub set_account {
	my ( $self, $account ) = @_;
	return undef if !$account;
	$self->{accountId} = $account;
	return 1;
}

# ==== SandBox ====

sub register_sandbox {
	my $self = shift;
	$self->{api_url} = $sanbox_url;
	my $result = $self->http_post( "/sandbox/register", '' );
	$self->{accountId} = $result->{payload}->{brokerAccountId} if $result;
	return $result;
}

sub set_currencies_balance {
	my $self = shift;
	my %params = ( currency => 'RUB', balance => 0, accountId => $self->{accountId}, @_ );
	my $result = $self->http_post( "/sandbox/currencies/balance?brokerAccountId=$params{accountId}", ( currency=> $params{currency}, balance => $params{balance}+0 ) );
	return $result;
}

sub set_positions_balance {
  my $self = shift;
  my %params = ( figi => '', balance => 0, accountId => $self->{accountId}, @_ );
	Carp::croak("You must provide figi") if !$params{figi};
  my $result = $self->http_post( "/sandbox/positions/balance?brokerAccountId=$params{accountId}", ( figi=> $params{figi}, balance => $params{balance}+0 ) );
  return $result;
}

sub sandbox_remove {
  my $self = shift;
  my %params = ( accountId => $self->{accountId}, @_ );
  my $result = $self->http_post( "/sandbox/remove?brokerAccountId=$params{accountId}", ( ) );
  return $result;
}

sub sandbox_clear {
  my $self = shift;
  my %params = ( accountId => $self->{accountId}, @_ );
  my $result = $self->http_get( "/sandbox/clear?brokerAccountId=$params{accountId}" );
  return $result;
}

#==== Orders ====

sub orders {
  my $self = shift;
  my %params = ( accountId => $self->{accountId}, @_ );
  my $result = $self->http_get( "/orders?brokerAccountId=$params{accountId}" );
  return $result;
}

sub limit_order {
  my $self = shift;
  my %params = ( operation => "Buy", accountId => $self->{accountId}, @_ );
  Carp::croak("You must provide figi, lots and price") if !$params{figi} or !$params{lots} or !$params{price};
  my $result = $self->http_post( "/orders/limit-order?brokerAccountId=$params{accountId}&figi=$params{figi}", ( lots=> $params{lots}+0, operation => $params{operation}, price => $params{price}+0 ) );
  return $result;
}

sub market_order {
  my $self = shift;
  my %params = ( operation => "Buy", accountId => $self->{accountId}, @_ );
  Carp::croak("You must provide figi and lots") if !$params{figi} or !$params{lots};
  my $result = $self->http_post( "/orders/market-order?brokerAccountId=$params{accountId}&figi=$params{figi}", ( lots=> $params{lots}+0, operation => $params{operation} ) );
  return $result;
}

sub cancel_order {
  my $self = shift;
  my %params = ( accountId => $self->{accountId}, @_ );
  Carp::croak("You must provide orderId") if !$params{orderId};
  my $result = $self->http_post( "/orders/cancel?brokerAccountId=$params{accountId}&orderId=$params{orderId}" );
  return $result;
}


#==== Portfolio ====

sub portfolio {
  my $self = shift;
  my %params = ( accountId => $self->{accountId}, @_ );
  my $result = $self->http_get( "/portfolio?brokerAccountId=$params{accountId}" );
  return $result;
}

sub portfolio_currencies {
  my $self = shift;
  my %params = ( accountId => $self->{accountId}, @_ );
  my $result = $self->http_get( "/portfolio/currencies?brokerAccountId=$params{accountId}" );
  return $result;
}

#==== Market ====

sub market_stocks {
  my ( $self ) = @_;
  my $result = $self->http_get( "/market/stocks" );
  return $result;
}

sub market_bonds {
  my ( $self ) = @_;
  my $result = $self->http_get( "/market/bonds" );
  return $result;
}

sub market_etfs {
  my ( $self ) = @_;
  my $result = $self->http_get( "/market/etfs" );
  return $result;
}

sub market_currencies {
  my ( $self ) = @_;
  my $result = $self->http_get( "/market/currencies" );
  return $result;
}

sub market_orderbook {
  my $self = shift;
  my %params = ( depth => 20, @_ );
  Carp::croak("You must provide figi and depth") if !$params{figi} or !$params{depth};
  my $result = $self->http_get( "/market/orderbook?figi=$params{figi}&depth=$params{depth}" );
  return $result;
}

sub market_candles {
  my $self = shift;
	my %params = ( @_ );
  Carp::croak("You must provide figi, from, to and interval") if !$params{figi} or !$params{from} or !$params{to} or !$params{interval};
  $params{from} = uri_escape( $params{from} );
  $params{to} = uri_escape( $params{to} );
  my $result = $self->http_get( "/market/candles?figi=$params{figi}&from=$params{from}&to=$params{to}&interval=$params{interval}" );
  return $result;
}

sub search_by_figi {
	my ( $self, $figi ) = @_;
	Carp::croak("You must provide figi") if !$figi;
	my $result = $self->http_get( "/market/search/by-figi?figi=$figi" );
	return $result;
}

sub search_by_ticker {
  my ( $self, $ticker ) = @_;
  Carp::croak("You must provide ticker") if !$ticker;
  my $result = $self->http_get( "/market/search/by-ticker?ticker=$ticker" );
  return $result;
}

#==== Operations ====

sub operations {
  my $self = shift;
  my %params = (  accountId => $self->{accountId}, @_ );
  Carp::croak("You must provide from and to") if !$params{from} or !$params{to};
	$params{from} = uri_escape( $params{from} );
	$params{to} = uri_escape( $params{to} );
	my $result = $self->http_get( "/operations?brokerAccountId=$params{accountId}&from=$params{from}&to=$params{to}".( $params{figi} ? "&figi=$params{figi}" : "" ) );
  return $result;
}


#==== User ====

sub accounts {
  my $self = shift;
  my $result = $self->http_get( "/user/accounts" );
  return $result;
}


sub http_get {
  my($self,$url) = @_;
	$url = $self->{api_url}.$url;

  print STDERR "\nUrl: $url\n" if $self->{debug};

  my $timeout = $self->{timeout};

  local @LWP::Protocol::http::EXTRA_SOCK_OPTS = (
    SendTE => 0
  );
  my $ua = LWP::UserAgent->new();
  $ua->timeout($timeout) if $timeout;
  my $request = HTTP::Request->new('GET', $url);
  $request->header( 'Authorization' => "Bearer $self->{token}" );
  my $response = $ua->request($request);

  my $status = $response->status_line;
  $self->{errstatus} = "$status";
  my $content = $response->decoded_content;
  $self->{returned_json} = $content;
  print STDERR "Status: $status Success: ".$response->is_success."\nContent: $content\n" if $self->{debug};

  $content = decode_json( $content );

  if ( !$response->is_success ) {
    $self->{errstr} = $content->{payload}->{message};
    return undef;
  }
  print Dumper($content) if $self->{debug};

  return $content;
};


sub http_post {
  my($self,$url,%data) = @_;
	$url = $self->{api_url}.$url;
	
	my $data = encode_json(\%data);
	print STDERR "\nUrl: $url\ndata: $data\n" if $self->{debug};

	my $timeout = $self->{timeout};

  local @LWP::Protocol::http::EXTRA_SOCK_OPTS = (
    SendTE => 0
  );
	my $ua = LWP::UserAgent->new();
	$ua->timeout($timeout) if $timeout;
	my $request = HTTP::Request->new('POST', $url);
	$request->header( 'Authorization' => "Bearer $self->{token}" );
	$request->content($data);
	my $response = $ua->request($request);

	my $status = $response->status_line;
	$self->{errstatus} = "$status";
	my $content = $response->decoded_content;
	$self->{returned_json} = $content;
	print STDERR "Status: $status Success: ".$response->is_success."\nContent: $content\n" if $self->{debug};

	$content = decode_json( $content );

	if ( !$response->is_success ) {
		$self->{errstr} = $content->{payload}->{message};
		return undef;
	}
	print Dumper($content) if $self->{debug};

	return $content;
};

1;

=head1 NAME

Tinkoff::Invest - Perl Tinkoff Invest OpenAPI interface

=head1 SYNOPSIS

	use strict;
	use warnings;

	use Tinkoff::Invest;

=head1 DESCRIPTION

L<Tinkoff::Invest> is a Perl module for Tinkoff Invest Api. You can find more information about REST protocol here: https://tinkoffcreditsystems.github.io/invest-openapi/swagger-ui/ . More guides and information here: https://tinkoffcreditsystems.github.io/invest-openapi/

=head1 CONSTRUCTOR

	$tinky = Tinkoff::Invest->new( token => $token, [ debug => 0 ] );

=head1 ATTRIBUTES

=head2 errstatus

	$tinky->{errstatus};

Returns status of last operation (mostly https request). C<200 OK> or C<500 Internal Server Error> for now.

=head2 errstr

	$tinky->{errstr};

Contains last error message. Pasred from C<<payload->message>> of returnes json. 

=head2 returned_json

	$tinky->{returned_json};

Contains returned json for last request.

=head1 METHODS

Methods mostly a simple request to an api. C<< [ name => default ] >> - optional parameters with default value.

=head2 register_sandbox

	$tinky->register_sandbox;

Registers sandbox and uses brokerAccountId for further methods (you may not pass accoountId).

=head2 set_currencies_balance

	$tinky->set_currencies_balance( [ currency => 'RUB', balance => 0, accountId => $brokerAccountId ] );

Sets the balance of currency.

=head2 set_positions_balance

	$tinky->set_positions_balance( figi => $figi, [ balance => 0, accountId => $brokerAccountId ] );

Sets balances for positions by figi.

=head2 sandbox_remove

	$tinky->sandbox_remove( [ accountId => $brokerAccountId ] );

Removes sandbox account

=head2 sandbox_clear

	$tinky->sandbox_clear( [ accountId => $brokerAccountId ] );

Clears all positions of client

=head2 orders

	$tinky->orders( [ accountId => $brokerAccountId ] );

Returns active orders.

=head2 limit_order

	$tinky->limit_order( figi => $figi, lots => $lots, price => $price, [ operation => 'Buy' ] );

Limit order creation. C<'Buy'> or C<'Sell'> operation.

=head2 market_order

	$tinky->market_order( figi => $figi, lots => $lots, [ operation => 'Buy' ] );

Creates market order. C<'Buy'> or C<'Sell'> operation.

=head2 cancel_order

	$tinky->cancel_order( orderId => $orderId );

Cancels order by orderId

=head2 portfolio

	$tinky->portfolio( [ accountId => $brokerAccountId ] );

Returns investor's portfolio (stocks, bonds, etfs and currencies).

=head2 portfolio_currencies

	$tinky->portfolio_currencies();

Returns short currencies balance.

=head2 market_stocks

	$tinky->market_stocks();

Returns information about all stocks.

=head2 market_bonds

	$tinky->market_bonds();

Returns information about all bonds.

=head2 market_etfs

	$tinky->market_etfs();

Returns information about all ETFs.

=head2 market_currencies

	$tinky->market_currencies();

Returns information about all currencies (currently there are RUB and USD only).

=head2 market_orderbook

	$tinky->market_orderbook( figi => $figi, [ depth => 20 ] );

Returns orderbook (asks and bids) by figi.

=head2 market_candles

	$tinky->market_candles( figi => $figi, from => $from, to => $from, interval => $interval );

Returns historical candles by figi. C<from> and C<to> must be ISO datetime with or without timezone (ex: '2021-06-14T00:00:00+03:00' or '2021-06-20T00:00:00Z' ). Available C<interval> values: 1min, 2min, 3min, 5min, 10min, 15min, 30min, hour, day, week, month .

=head2 search_by_figi

	$tinky->search_by_figi( $figi );

Returns information by figi ( name, ticker etc. ).

=head2 search_by_ticker

	$tinky->search_by_ticker( $ticker );

Returns information by ticker ( name, ticker etc. ).

=head2 operations

	$tinky->operations(from=>$datetime_from, to=>$datetime_to, [ figi => '', accountId => $brokerAccountId ] );

Returns operations for interval. C<from> and C<to> must be ISO datetime with or without timezone (ex: '2021-06-14T00:00:00+03:00' or '2021-06-20T00:00:00Z' ). If C<figi> is omitted all operations if this interval will be returned.

=head2 accounts

	$accounts = $tinky->accounts();

Returns all acounts.

=head2 set_account

	$tinky->set_account( $brokerAccountId );

Sets account for use as a default for further methods (you may not pass accoountId).
Example:

	$accounts = $tinky->accounts();
	$tinky->set_account( $accounts->{payload}->{accounts}[0]->{brokerAccountId} );
	$tinky->operations( from=>'2021-06-14T00:00:00+03:00', to => '2021-06-20T00:00:00Z' ); # accountId is omitted

=cut	

