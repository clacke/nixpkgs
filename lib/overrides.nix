{ lib }:

# Overlays, overrides, and other mechanisms for extensiblilty.

let brand = "extensible-attrset"; in

rec {
  #
  monoidalExtension = { append, identity }: {
    identity = _: _: identity;
    append = f: g: self: super:
      let fApplied = f self super;
        super' = append super fApplied;
      in append fApplied (g self super');
  };

  #
  fixMondoidalExtension = { append, identity }:
    override: lib.fix (self: override self identity);

  #
  extendMonoidal = { append, identity }:
    f: rattrs: self: let super = rattrs self; in append super (f self super);

  #
  mergeExtensibleRecursive = zipAttrsWith (n: vs:
    if builtins.length vs > 1 && lib.all (a: a.type == brand)
      then lib.foldl extensibleAttrset.identity extensibleAttrset.append vs
      else lib.last vs);

  #
  attrsetDeep = {
    identity = {};
    append = old: new: mergeExtensibleRecursive old new
  };

  #
  extensibleAttrset = {
    identity = { __override__ = self: super: {}; };
    append = old: new: makeExtensibleAttrset
      (composeExtensions old.__override__ new.__override__);
  };

  makeExtensibleAttrset = __override__:
    fixMondoidalExtension attrsetDeep __override__ // {
      inherit __override__;
    };

  # Modify the contents of an explicitly recursive attribute set in a way that
  # honors `self`-references. This is accomplished with a function
  #
  #     g = self: super: { foo = super.foo + " + "; }
  #
  # that has access to the unmodified input (`super`) as well as the final
  # non-recursive representation of the attribute set (`self`). `extends`
  # differs from the native `//` operator insofar as that it's applied *before*
  # references to `self` are resolved:
  #
  #     nix-repl> fix (extends g f)
  #     { bar = "bar"; foo = "foo + "; foobar = "foo + bar"; }
  #
  # The name of the function is inspired by object-oriented inheritance, i.e.
  # think of it as an infix operator `g extends f` that mimics the syntax from
  # Java. It may seem counter-intuitive to have the "base class" as the second
  # argument, but it's nice this way if several uses of `extends` are cascaded.
  extends = extendMonoidal lib.monoid.attrsetDeep;

  # Compose two extending functions of the type expected by 'extends'
  # into one where changes made in the first are available in the
  # 'super' of the second
  composeExtensions = (monoidalExtension lib.monoid.attrsetDeep).append;

  # Create an overridable, recursive attribute set. For example:
  #
  #     nix-repl> obj = makeExtensible (self: { })
  #
  #     nix-repl> obj
  #     { __unfix__ = «lambda»; extend = «lambda»; }
  #
  #     nix-repl> obj = obj.extend (self: super: { foo = "foo"; })
  #
  #     nix-repl> obj
  #     { __unfix__ = «lambda»; extend = «lambda»; foo = "foo"; }
  #
  #     nix-repl> obj = obj.extend (self: super: { foo = super.foo + " + "; bar = "bar"; foobar = self.foo + self.bar; })
  #
  #     nix-repl> obj
  #     { __unfix__ = «lambda»; bar = "bar"; extend = «lambda»; foo = "foo + "; foobar = "foo + bar"; }
  makeExtensible = rattrs:
    makeExtensibleAttrset (self: super: rattrs self) // rec {
      __unfix__ = extends f rattrs;
      extend = f: makeExtensible __unfix__;
    };
}
