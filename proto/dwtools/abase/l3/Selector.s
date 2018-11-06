( function _Selector_s_() {

'use strict';

/**
  @module Tools/base/Selector - Collection of routines to select a sub-structure from a complex data structure. Use the module to transform a data structure with the help of a short query string.
*/

/**
 * @file Selector.s.
 */

if( typeof module !== 'undefined' )
{

  let _ = require( '../../Tools.s' );

  _.include( 'wLooker' );
  _.include( 'wPathFundamentals' );

}

let _global = _global_;
let Self = _global_.wTools;
let _ = _global_.wTools;

let _ArraySlice = Array.prototype.slice;
let _FunctionBind = Function.prototype.bind;
let _ObjectToString = Object.prototype.toString;
let _ObjectHasOwnProperty = Object.hasOwnProperty;

_.assert( !!_realGlobal_ );

/*
_entitySelectOptions.defaults =
{
  container : null,
  query : null,
  set : null,
  delimeter : [ '.','/','[',']' ],
  missingAction : 'undefine',
  usingIndexedAccessToMap : 1,
  usingSet : 0,
  onElement : null,
}
*/

// --
// selector
// --

let Looker = _.mapExtend( null, _.look.defaults.looker );
Looker.Iteration = _.mapExtend( null, Looker.Iteration );
Looker.Iteration.apath = null;
Looker.Iteration.query = null;
Looker.Iteration.onResultWrite = null;
Looker.Iteration.isActual = null;
Looker.Iterator = _.mapExtend( null, Looker.Iterator );
Looker.Iterator.aquery = null;
Looker.Defaults = _.mapExtend( null, Looker.Defaults );
Looker.Defaults.aquery = null;

//

function errDoesNotExistThrow( it )
{
  let c = it.context;
  if( c.missingAction === 'undefine' || c.missingAction === 'ignore' )
  it.result = undefined
  else
  throw _.err
  (
    'Cant select', _.strQuote( it.context.query ),
    '\nbecause', _.strQuote( _.path.join.apply( _.path, it.apath ) ), 'does not exist',
    '\nat', _.strQuote( it.path ),
    '\nin container', _.toStr( c.container )
  );
}

//

function errCantSetThrow( it )
{
  let c = it.context; debugger;
  throw _.err
  (
    'Cant set', _.strQuote( it.context.query ),
    'of container', _.toStr( c.container )
  );
}

//

function errNoDownThrow( it )
{
  let c = it.context;
  throw _.err
  (
    'Cant go down', _.strQuote( it.context.query ),
    '\nbecause', _.strQuote( _.path.join.apply( _.path, it.apath ) ), 'does not exist',
    '\nat', _.strQuote( it.path ),
    '\nin container', _.toStr( c.container )
  );
}

//

function _entitySelect_pre( routine, args )
{

  let o = args[ 0 ]
  if( args.length === 2 )
  {
    o = { container : args[ 0 ], query : args[ 1 ] }
  }

  _.assert( arguments.length === 2 );
  _.assert( args.length === 1 || args.length === 2 );
  _.routineOptionsPreservingUndefines( routine, o ); /* xxx */

  _.assert( o.onTransient === null || _.routineIs( o.onTransient ) );
  _.assert( o.onActual === null || _.routineIs( o.onActual ) );

  _.assert( _.strIs( o.query ) );
  _.assert( !_.strHas( o.query, '.' ) || _.strHas( o.query, '..' ), 'Temporary : query should not have dots' );

  _.assert( _.arrayHas( [ 'undefine', 'ignore', 'throw' ], o.missingAction ), 'Unknown missing action', o.missingAction );
  // _.assert( _.arrayHas( [ 'result', 'src' ], o.returning ), 'Unknown returning', o.returning );

  if( o.setting === null && o.set !== null )
  o.setting = 1;

  // if( o.setting )
  // o.onActual = _.routinesCompose( o.onActual, handleSet );

  return _.look.pre( _.look, [ optionsFor( o ) ] );

  /* */

  function optionsFor( o )
  {

    _.assert( arguments.length === 1 );

    let o2 = Object.create( null );
    o2.src = o.container;
    o2.context = o;
    o2.onUp = handleUp;
    o2.onDown = handleDown;
    o2.looker = Looker;

    if( _.numberIs( o.query ) )
    o2.aquery = [ o.query ];
    else
    o2.aquery = _.strSplit
    ({
      src : o.query,
      delimeter : o.delimeter,
      preservingDelimeters : 0,
      preservingEmpty : 0,
      stripping : 1,
    });

    return o2;
  }

  /* */

  function handleUp()
  {
    let it = this;
    let c = it.context;

    debugger;

    it.query = it.down ? it.iterator.aquery[ it.down.apath.length ] : it.iterator.aquery[ 0 ];
    it.apath = it.down ? it.down.apath.slice() : [];
    it.apath.push( it.query );
    it.isActual = it.query === undefined;

    if( it.isActual )
    {
      /* actual node */
      it.looking = false;
      it.result = it.src;
    }
    else if( _.strBegins( it.query, '*' ) )
    {
      /* all selector */
      if( _.arrayLike( it.src ) )
      {
        it.result = [];
        it.onResultWrite = function( eit )
        {
          if( c.missingAction === 'ignore' && eit.result === undefined )
          return;
          this.result.push( eit.result );
        }
      }
      else if( _.objectLike( it.src ) )
      {
        it.result = Object.create( null );
        it.onResultWrite = function( eit )
        {
          if( c.missingAction === 'ignore' && eit.result === undefined )
          return;
          this.result[ eit.key ] = eit.result;
        }
      }
      else
      {
        errDoesNotExistThrow( it );
      }
    }
    else
    {
      /* select single */

      if( _.primitiveIs( it.src ) )
      {
        errDoesNotExistThrow( it );
      }
      else if( it.context.usingIndexedAccessToMap && _.objectLike( it.src ) && !isNaN( _.numberFromStr( it.query ) ) )
      {
        let q = _.numberFromStr( it.query );
        it.query = _.mapKeys( it.src )[ q ];
        if( it.query === undefined )
        errDoesNotExistThrow( it );
        // it.result = it.src[ it.query ];
      }
      else if( it.src[ it.query ] === undefined )
      {
        errDoesNotExistThrow( it );
      }
      else
      {
        // it.result = it.src[ it.query ];
      }

      it.looking = false;
      it.onResultWrite = function( eit )
      {
        this.result = eit.result;
      }

    }

  }

  /* */

  function handleDown()
  {
    let it = this;
    let c = it.context;

    debugger;

    if( !it.query )
    {
    }
    else if( it.query === c.downToken )
    {
      let counter = 0;
      let dit = it.down;

      if( !dit )
      errNoDownThrow( it );

      while( dit.query === c.downToken || counter > 0 )
      {
        if( dit.query === c.downToken )
        counter += 1;
        else
        counter -= 1;
        dit = dit.down;
        if( !dit )
        errNoDownThrow( it );
      }

      dit = dit.iteration();
      dit.down = it;
      dit.look();

    }
    else if( _.strBegins( it.query, '*' ) )
    {
      if( it.query !== '*' )
      {
        debugger;
        let number = _.numberFromStr( _.strRemoveBegin( it.query, '*' ) );
        _.sure( !isNaN( number ) && number >= 0 );
        _.sure( _.entityLength( it.result ) === number );
      }
    }
    else
    {

      if( _.primitiveIs( it.src ) )
      return errDoesNotExistThrow( it );

      it.iteration().select( it.query ).look();

    }

    if( it.context.onTransient )
    it.context.onTransient( it );

    if( it.context.onActual && it.isActual )
    it.context.onActual( it );

    if( it.context.setting && it.isActual )
    {
      if( it.down )
      it.down.src[ it.key ] = it.context.set;
      else
      errCantSetThrow( it );
    }

    if( it.down )
    it.down.onResultWrite( it );

    return it.result;
  }

}

//

function _entitySelect_body( it )
{

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.assert( _.objectIs( it.looker ) );
  _.assert( _.prototypeOf( it.looker, it ) );

  it.iteration = it.context.iteration = _.look.body( it );

  // return it.returning === 'result' ? it.result : it.src;

  return it.result;
}

_entitySelect_body.defaults =
{
  container : null,
  query : null,
  missingAction : 'undefine',
  // returning : 'result',
  usingIndexedAccessToMap : 1,
  delimeter : '/',
  downToken : '..',
  onTransient : null,
  onActual : null,
  set : null,
  setting : null,
}

//

let entitySelect2 = _.routineFromPreAndBody( _entitySelect_pre, _entitySelect_body );

//

let entitySelectSet2 = _.routineFromPreAndBody( entitySelect2.pre, entitySelect2.body );

var defaults = entitySelectSet2.defaults;

defaults.set = null;
defaults.setting = 1;

//

function _entitySelectUnique_body( o )
{
  _.assert( arguments.length === 1 );

  let result = _.entitySelect.body( o );
  if( _.arrayHas( o.iteration.iterator.aquery, '*' ) )
  result = _.arrayUnique( result );

  return result;
}

_.routineExtend( _entitySelectUnique_body, entitySelect2.body );

let entitySelectUnique2 = _.routineFromPreAndBody( entitySelect2.pre, _entitySelectUnique_body );

// //
//
// /**
//  * Returns generated options object( o ) for ( entitySelect ) routine.
//  * Query( o.query ) can be represented as string or array of strings divided by one of( o.delimeter ).
//  * Function parses( o.query ) in to array( o.qarrey ) by splitting string using( o.delimeter ).
//  *
//  * @param {Object|Array} [ o.container=null ] - Source entity.
//  * @param {Array|String} [ o.query=null ] - Source query.
//  * @param {*} [ o.set=null ] - Specifies value that replaces selected.
//  * @param {Array} [ o.delimeter=[ '.','[',']' ] ] - Specifies array of delimeters for( o.query ) values.
//  * @param {Boolean} [ o.undefinedForMissing=false ] - If true returns undefined for Atomic type of( o.container ).
//  * @returns {Object} Returns generated options object.
//  *
//  * @example
//  * //returns { container: [ 0, 1, 2, 3 ], qarrey : [ '0', '1', '2' ], query: "0.1.2", set: 1, delimeter: [ '.','[',']' ], undefinedForMissing: 1 }
//  * _._entitySelectOptions( { container : [ 0, 1, 2, 3 ], query : '0.1.2', set : 1 } );
//  *
//  * @function _entitySelectOptions
//  * @throws {Exception} If( arguments.length ) is not equal 1 or 2.
//  * @throws {Exception} If( o.query ) is not a String or Array.
//  * @memberof wTools
// */
//
// function _entitySelectOptions( o )
// {
//
//   if( arguments[ 1 ] !== undefined )
//   {
//     o = Object.create( null );
//     o.container = arguments[ 0 ];
//     o.query = arguments[ 1 ];
//   }
//
//   if( o.usingSet === undefined && o.set )
//   o.usingSet = 1;
//
//   _.assert( arguments.length === 1 || arguments.length === 2 );
//   _.routineOptionsPreservingUndefines( _entitySelectOptions, o );
//   _.assert( _.strIs( o.query ) || _.numberIs( o.query ) || _.arrayIs( o.query ) );
//
//   /* */
//
//   if( _.arrayIs( o.query ) )
//   {
//     o.qarrey = [];
//     for( let i = 0 ; i < o.query.length ; i++ )
//     o.qarrey[ i ] = makeQarrey( o.query[ i ] );
//   }
//   else
//   {
//     o.qarrey = makeQarrey( o.query );
//   }
//
//   return o;
//
//   /* makeQarrey */
//
//   function makeQarrey( query )
//   {
//     let qarrey;
//
//     if( _.numberIs( query ) )
//     qarrey = [ query ];
//     else
//     qarrey = _.strSplitNaive
//     ({
//       src : query,
//       delimeter : o.delimeter,
//       preservingDelimeters : 0,
//       preservingEmpty : 0,
//       stripping : 1,
//     });
//
//     if( qarrey[ 0 ] === '' )
//     qarrey.splice( 0,1 );
//
//     return qarrey;
//   }
//
// }
//
// _entitySelectOptions.defaults =
// {
//   container : null,
//   query : null,
//   set : null,
//   delimeter : [ '.','/','[',']' ],
//   undefinedForMissing : 1,
//   usingIndexedAccessToMap : 1,
//   usingSet : 0,
//   onElement : null,
// }
//
// //
//
// function _entitySelect( o )
// {
//   let result;
//
//   if( _.arrayIs( o.query ) )
//   {
//     debugger;
//
//     result = Object.create( null );
//     for( let i = 0 ; i < o.query.length ; i++ )
//     {
//
//       let optionsForSelect = _.mapExtend( null,o );
//       optionsForSelect.query = optionsForSelect.query[ i ];
//
//       debugger;
//       _.assert( 0,'not tested' );
//       result[ iterator.query ] = _entitySelectAct( it,iterator );
//     }
//
//     return result;
//   }
//
//   // debugger;
//   o = _entitySelectOptions( o );
//
//   let iterator = Object.create( null );
//   iterator.set = o.set;
//   iterator.delimeter = o.delimeter;
//   iterator.undefinedForMissing = o.undefinedForMissing;
//   iterator.usingIndexedAccessToMap = o.usingIndexedAccessToMap;
//   iterator.onElement = o.onElement;
//   iterator.usingSet = o.usingSet;
//   iterator.query = o.query;
//
//   let it = Object.create( null );
//   it.qarrey = o.qarrey;
//   it.container = o.container;
//   it.up = null;
//
//   result = _entitySelectAct( it,iterator );
//
//   return result;
// }
//
// //
//
// /**
//  * Returns value from entity that corresponds to index / key or path provided by( o.qarrey ) from entity( o.container ).
//  *
//  * @param {Object|Array} [ o.container=null ] - Source entity.
//  * @param {Array} [ o.qarrey=null ] - Specifies key/index to select or path to element. If has '*' routine processes each element of container.
//  * Example process each element at [ 0 ]: { container : [ [ 1, 2, 3 ] ], qarrey : [ 0, '*' ] }.
//  * Example path to element [ 1 ][ 1 ]: { container : [ 0, [ 1, 2 ] ],qarrey : [ 1, 1 ] }.
//  * @param {*} [ o.set=null ] - Replaces selected index/key value with this. If defined and specified index/key not exists, routine inserts it.
//  * @param {Boolean} [ o.undefinedForMissing=false ] - If true returns undefined for Atomic type of( o.container ).
//  * @returns {*} Returns value finded by index/key or path.
//  *
//  * @function _entitySelectAct
//  * @throws {Exception} If container is Atomic type.
//  * @memberof wTools
// */
//
// function _entitySelectAct( it,iterator )
// {
//
//   let result;
//   let container = it.container;
//
//   let key = it.qarrey[ 0 ];
//   let key2 = it.qarrey[ 1 ];
//
//   if( !it.qarrey.length )
//   {
//     if( iterator.onElement )
//     return iterator.onElement( it,iterator );
//     else
//     return container;
//   }
//
//   _.assert( Object.keys( iterator ).length === 7 );
//   _.assert( Object.keys( it ).length === 3 );
//   _.assert( arguments.length === 2, 'Expects exactly two arguments' );
//
//   if( _.primitiveIs( container ) )
//   {
//     if( iterator.undefinedForMissing )
//     return undefined;
//     else
//     throw _.err( 'cant select',it.qarrey.join( '.' ),'from atomic',_.strTypeOf( container ) );
//   }
//
//   let qarrey = it.qarrey.slice( 1 );
//
//   /* */
//
//   function _select( key )
//   {
//
//     if( !qarrey.length && iterator.usingSet )
//     {
//       if( iterator.set === undefined )
//       delete container[ key ];
//       else
//       container[ key ] = iterator.set;
//     }
//
//     let field;
//     if( iterator.usingIndexedAccessToMap && _.numberIs( key ) && _.objectIs( container ) )
//     field = _.mapValWithIndex( container, key );
//     else
//     field = container[ key ];
//
//     if( field === undefined && iterator.usingSet )
//     {
//       if( !isNaN( key2 ) )
//       {
//         container[ key ] = field = [];
//       }
//       else
//       {
//         container[ key ] = field = Object.create( null );
//       }
//     }
//
//     if( field === undefined )
//     return;
//
//     let newIteration = Object.create( null );
//     newIteration.container = field;
//     newIteration.qarrey = qarrey;
//     newIteration.up = container;
//
//     return _entitySelectAct( newIteration,iterator );
//   }
//
//   /* */
//
//   if( key === '*' )
//   {
//
//     result = _.entityMakeTivial( container );
//     _.each( container,function( e,k )
//     {
//       result[ k ] = _select( k );
//     });
//
//   }
//   else
//   {
//     result = _select( key );
//   }
//
//   return result;
// }
//
// //
//
// function entitySelect( o )
// {
//
//   // o = _entitySelectOptions( arguments[ 0 ],arguments[ 1 ] );
//
//   if( arguments[ 1 ] !== undefined )
//   {
//     o = Object.create( null );
//     o.container = arguments[ 0 ];
//     o.query = arguments[ 1 ];
//   }
//
//   _.assert( arguments.length === 1 || arguments.length === 2 );
//
//   let result = _entitySelect( o );
//
//   return result;
// }
//
// entitySelect.defaults =
// {
// }
//
// entitySelect.defaults.__proto__ = _entitySelectOptions.defaults;
//
// //
//
// function entitySelectSet( o )
// {
//
//   _.assert( arguments.length === 1 || arguments.length === 3 );
//
//   if( arguments[ 1 ] !== undefined || arguments[ 2 ] !== undefined )
//   {
//     o = Object.create( null );
//     o.container = arguments[ 0 ];
//     o.query = arguments[ 1 ];
//     o.set = arguments[ 2 ];
//   }
//   else
//   {
//     _.assert( _.mapOwnKey( o,{ set : 'set' } ) );
//   }
//
//   o.usingSet = 1;
//
//   let result = _entitySelect( o );
//
//   return result;
// }
//
// entitySelectSet.defaults =
// {
//   set : null,
//   usingSet : 1,
// }
//
// entitySelectSet.defaults.__proto__ = _entitySelectOptions.defaults;
//
// //
//
// function entitySelectUnique( o )
// {
//
//   if( arguments[ 1 ] !== undefined )
//   {
//     o = Object.create( null );
//     o.container = arguments[ 0 ];
//     o.query = arguments[ 1 ];
//   }
//
//   // o = _entitySelectOptions( arguments[ 0 ],arguments[ 1 ] );
//
//   _.assert( arguments.length === 1 || arguments.length === 2 );
//   // _.assert( _.arrayCount( o.qarrey,'*' ) <= 1,'not implemented' );
//   // debugger;
//
//   let result = _entitySelect( o );
//
//   // debugger;
//
//   if( o.qarrey.indexOf( '*' ) !== -1 )
//   if( _.longIs( result ) )
//   result = _.arrayUnique( result );
//
//   return result;
// }
//
// entitySelectUnique.defaults =
// {
// }
//
// entitySelectUnique.defaults.__proto__ = _entitySelectOptions.defaults;

//

function _entityProbeReport( o )
{

  _.assert( arguments.length );
  o = _.routineOptions( _entityProbeReport,o );

  /* report */

  if( o.report )
  {
    if( !_.strIs( o.report ) )
    o.report = '';
    o.report += o.title + ' : ' + o.total + '\n';
    for( let r in o.result )
    {
      let d = o.result[ r ];
      o.report += o.tab;
      if( o.prependingByAsterisk )
      o.report += '*.';
      o.report += r + ' : ' + d.having.length;
      if( d.values )
      o.report += ' ' + _.toStrShort( d.values );
      o.report += '\n';
    }
  }

  return o.report;
}

_entityProbeReport.defaults =
{
  title : null,
  report : null,
  result : null,
  total : null,
  prependingByAsterisk : 1,
  tab : '  ',
}

//

function entityProbeField( o )
{

  if( arguments[ 1 ] !== undefined )
  {
    o = Object.create( null );
    o.container = arguments[ 0 ];
    o.query = arguments[ 1 ];
  }

  _.routineOptions( entityProbeField,o );

  _.assert( arguments.length === 1 || arguments.length === 2 );
  o.all = _entitySelect( _.mapOnly( o, _entitySelectOptions.defaults ) );
  o.onElement = function( it ){ return it.up };
  o.parents = _entitySelect( _.mapOnly( o, _entitySelectOptions.defaults ) );
  o.result = Object.create( null );

  /* */

  for( let i = 0 ; i < o.all.length ; i++ )
  {
    let val = o.all[ i ];
    if( !o.result[ val ] )
    {
      let d = o.result[ val ] = Object.create( null );
      d.having = [];
      d.notHaving = [];
      d.value = val;
    }
    let d = o.result[ val ];
    d.having.push( o.parents[ i ] );
  }

  for( let k in o.result )
  {
    let d = o.result[ k ];
    for( let i = 0 ; i < o.all.length ; i++ )
    {
      let element = o.all[ i ];
      let parent = o.parents[ i ];
      if( !_.arrayHas( d.having, parent ) )
      d.notHaving.push( parent );
    }
  }

  /* */

  if( o.report )
  {
    if( o.title === null )
    o.title = o.query;
    o.report = _._entityProbeReport
    ({
      title : o.title,
      report : o.report,
      result : o.result,
      total : o.all.length,
      prependingByAsterisk : 0,
    });
  }

  return o;
}

entityProbeField.defaults = Object.create( entitySelect2.defaults );

entityProbeField.defaults.title = null;
entityProbeField.defaults.report = 1;

//

function entityProbe( o )
{

  if( _.arrayIs( o ) )
  o = { src : o }

  _.assert( arguments.length === 1, 'Expects single argument' );
  _.routineOptions( entityProbe,o );
  _.assert( _.arrayIs( o.src ) || _.objectIs( o.src ) );

  o.result = o.result || Object.create( null );
  o.all = o.all || [];

  /* */

  _.entityMap( o.src, function( src,k )
  {

    o.total += 1;

    if( !_.longIs( src ) || !o.recursive )
    {
      _.assert( _.objectIs( src ) );
      if( src !== undefined )
      extend( o.result, src );
      return src;
    }

    for( let s = 0 ; s < src.length ; s++ )
    {
      if( _.arrayIs( src[ s ] ) )
      entityProbe
      ({
        src : src[ s ],
        result : o.result,
        assertingUniqueness : o.assertingUniqueness,
      });
      else if( _.objectIs( src[ s ] ) )
      extend( o.result, src );
      else
      throw _.err( 'array should have only maps' );
    }

    return src;
  });

  /* not having */

  for( let a = 0 ; a < o.all.length ; a++ )
  {
    let map = o.all[ a ];
    for( let r in o.result )
    {
      let field = o.result[ r ];
      if( !_.arrayHas( field.having,map ) )
      field.notHaving.push( map );
    }
  }

  if( o.report )
  o.report = _._entityProbeReport
  ({
    title : o.title,
    report : o.report,
    result : o.result,
    total : o.total,
    prependingByAsterisk : 1,
  });

  return o;

  /* */

  function extend( result,src )
  {

    o.all.push( src );

    if( o.assertingUniqueness )
    _.assertMapHasNone( result,src );

    for( let s in src )
    {
      if( !result[ s ] )
      {
        let r = result[ s ] = Object.create( null );
        r.times = 0;
        r.values = [];
        r.having = [];
        r.notHaving = [];
      }
      let r = result[ s ];
      r.times += 1;
      let added = _.arrayAppendedOnce( r.values,src[ s ] ) !== -1;
      r.having.push( src );
    }

  }

}

entityProbe.defaults =
{
  src : null,
  result : null,
  recursive : 0,
  report : 1,
  total : 0,
  all : null,
  title : 'Probe',
}

// --
// declare
// --

let Proto =
{

  entitySelect : entitySelect2,
  entitySelectSet : entitySelectSet2,
  entitySelectUnique : entitySelectUnique2,

  // _entitySelectOptions : _entitySelectOptions,
  // _entitySelect : _entitySelect,
  // _entitySelectAct : _entitySelectAct,
  // entitySelect : entitySelect,
  // entitySelectSet : entitySelectSet,
  // entitySelectUnique : entitySelectUnique,

  _entityProbeReport : _entityProbeReport,
  entityProbeField : entityProbeField,
  entityProbe : entityProbe,

}

_.mapSupplement( Self, Proto );

// --
// export
// --

if( typeof module !== 'undefined' )
if( _global_.WTOOLS_PRIVATE )
{ /* delete require.cache[ module.id ]; */ }

if( typeof module !== 'undefined' && module !== null )
module[ 'exports' ] = Self;

})();
